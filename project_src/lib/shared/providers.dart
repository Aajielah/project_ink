import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/connection/native.dart'
    if (dart.library.html) '../database/connection/web.dart' as native;
import '../models/project.dart';
import '../models/schedule.dart';
import '../models/today_writing_task.dart';

import '../models/settings.dart';
import '../models/statistics.dart';
import '../models/quote.dart';
import '../repositories/project_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/statistics_repository.dart';
import '../repositories/quote_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/scheduling_service.dart';
import '../services/logging_service.dart';
import '../services/encouragement_service.dart';
import '../services/backup_service.dart';
import '../services/ongoing_sync_service.dart';
import '../services/notification_service.dart';
import '../services/project_lifecycle_service.dart';
import 'date_utils.dart';
import 'package:flutter/foundation.dart';

// --- Database & Connection Provider ---
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(native.connect());
  ref.onDispose(() => db.close());
  return db;
});

// --- Repositories Providers ---
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(dbProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(dbProvider));
});

final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository(ref.watch(dbProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(dbProvider));
});

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(ref.watch(dbProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dbProvider));
});

// --- Services Providers ---
final schedulingServiceProvider = Provider<SchedulingService>((ref) {
  return const SchedulingService();
});

final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService(
    ref.watch(projectRepositoryProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(dailyLogRepositoryProvider),
    ref.watch(statisticsRepositoryProvider),
  );
});

final encouragementServiceProvider = Provider<EncouragementService>((ref) {
  return EncouragementService(
    ref.watch(quoteRepositoryProvider),
    ref.watch(projectRepositoryProvider),
    ref.watch(dailyLogRepositoryProvider),
    ref.watch(statisticsRepositoryProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(dbProvider));
});

final projectLifecycleServiceProvider = Provider<ProjectLifecycleService>((ref) {
  return ProjectLifecycleService(
    ref.watch(projectRepositoryProvider),
    ref.watch(dailyLogRepositoryProvider),
  );
});

// --- State Notifiers & Providers ---

// Projects State Notifier
class ProjectsNotifier extends StateNotifier<AsyncValue<List<ProjectModel>>> {
  final ProjectRepository _projectRepo;
  final SchedulingService _schedulingService;
  final ScheduleRepository _scheduleRepo;
  final OngoingSyncService _syncService;
  final DailyLogRepository _dailyLogRepo;
  final StatisticsRepository _statsRepo;
  final Ref _ref;

  ProjectsNotifier(
    this._projectRepo,
    this._schedulingService,
    this._scheduleRepo,
    this._syncService,
    this._dailyLogRepo,
    this._statsRepo,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      final list = await _projectRepo.getAllProjects();
      
      // Auto-activation sweep: Check if any upcoming project start date is reached/passed
      final today = getLogicalToday();
      final cleanToday = DateTime(today.year, today.month, today.day);
      bool listChanged = false;
      
      for (final p in list) {
        if (p.status == ProjectStatus.upcoming) {
          final cleanStartDate = DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
          if (!cleanStartDate.isAfter(cleanToday)) {
            final updatedProject = p.copyWith(
              status: ProjectStatus.active,
              updatedAt: DateTime.now(),
            );
            await _projectRepo.updateProject(updatedProject);
            listChanged = true;
          }
        }
      }
      
      final finalList = listChanged ? await _projectRepo.getAllProjects() : list;
      final active = finalList.where((p) => p.status == ProjectStatus.active).toList();
      final activeOngoing = active.where((p) => p.projectType == ProjectType.ongoing).toList();
      
      if (activeOngoing.isNotEmpty) {
        await _syncService.syncOngoingSchedules(activeOngoing);
      }
      
      final activeFixed = active.where((p) => p.projectType != ProjectType.ongoing).toList();
      if (activeFixed.isNotEmpty) {
        await _syncService.syncFixedGoalBacklogs(activeFixed);
      }
      
      // Apply pending carry forward credit for active projects (both fixed and ongoing)
      final loggingService = _ref.read(loggingServiceProvider);
      await loggingService.checkAndApplyPendingCarryForward(active);

      // Check and pause inactive projects
      final lifecycleService = _ref.read(projectLifecycleServiceProvider);
      await lifecycleService.checkAndPauseInactiveProjects(active);

      final updatedList = await _projectRepo.getAllProjects();
      state = AsyncValue.data(updatedList);
      await _updateNotificationSchedule(updatedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _updateNotificationSchedule(List<ProjectModel> projects) async {
    try {
      final settings = await _ref.read(settingsRepositoryProvider).getSettings();
      if (settings == null || !settings.notifications) {
        await NotificationService.instance.cancelDaily12AMNotification();
        await NotificationService.instance.cancelDailyMorningNotification();
        await NotificationService.instance.cancelDailyEveningNotification();
        return;
      }

      final active = projects.where((p) => p.status == ProjectStatus.active).toList();
      if (active.isEmpty) {
        await NotificationService.instance.cancelDaily12AMNotification();
        await NotificationService.instance.cancelDailyMorningNotification();
        await NotificationService.instance.cancelDailyEveningNotification();
        return;
      }

      final today = getLogicalToday();

      // Check if a group of projects has any incomplete writing targets today
      Future<bool> hasIncompleteTarget(List<ProjectModel> group) async {
        if (group.isEmpty) return false;
        for (final p in group) {
          final schedule = await _scheduleRepo.getScheduleForDate(p.id, today);
          if (schedule != null && !schedule.isRestDay) {
            final log = await _dailyLogRepo.getLogForDate(p.id, today);
            final logged = log?.actualWords ?? 0;
            if (logged < schedule.plannedWords) {
              return true; // Found an incomplete target in this group
            }
          }
        }
        return false;
      }

      final morningProjects = active.where((p) => p.writingSession == 'morning').toList();
      final eveningProjects = active.where((p) => p.writingSession == 'evening').toList();
      final noneProjects = active.where((p) => p.writingSession != 'morning' && p.writingSession != 'evening').toList();

      final morningIncomplete = await hasIncompleteTarget(morningProjects);
      final eveningIncomplete = await hasIncompleteTarget(eveningProjects);
      final noneIncomplete = await hasIncompleteTarget(noneProjects);

      // Morning reminders (12:00 PM)
      if (morningIncomplete) {
        await NotificationService.instance.scheduleDailyMorningNotification();
      } else {
        await NotificationService.instance.cancelDailyMorningNotification();
      }

      // Evening reminders (8:00 PM)
      if (eveningIncomplete) {
        await NotificationService.instance.scheduleDailyEveningNotification();
      } else {
        await NotificationService.instance.cancelDailyEveningNotification();
      }

      // Global/No Preference reminders (12:00 AM)
      if (noneIncomplete) {
        await NotificationService.instance.scheduleDaily12AMNotification();
      } else {
        await NotificationService.instance.cancelDaily12AMNotification();
      }
    } catch (e) {
      debugPrint('Error updating notification schedule: $e');
    }
  }

  Future<String?> addProject({
    required String name,
    String? description,
    ProjectType projectType = ProjectType.fixed,
    required int targetWords,
    required int dailyWordTarget,
    required int durationDays,
    required DateTime startDate,
    required RestMode restMode,
    required List<int> fixedRestWeekdays,
    required int allowedRestDays,
    String? coverImagePath,
    String? coverType,
    String ongoingStyle = 'daily',
    String writingSession = 'none',
  }) async {
    if (projectType == ProjectType.fixed) {
      final err = _schedulingService.validateInputs(
        targetWords: targetWords,
        dailyWordTarget: dailyWordTarget,
        durationDays: durationDays,
        restMode: restMode,
        fixedRestWeekdays: fixedRestWeekdays,
        allowedRestDays: allowedRestDays,
      );
      if (err != null) return err;
    }

    try {
      final uuid = const Uuid();
      final projectId = uuid.v4();
      final today = getLogicalToday();
      final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final cleanToday = DateTime(today.year, today.month, today.day);

      if (projectType == ProjectType.fixed) {
        final schedules = _schedulingService.generateInitialSchedule(
          projectId: projectId,
          startDate: startDate,
          targetWords: targetWords,
          dailyWordTarget: dailyWordTarget,
          durationDays: durationDays,
          restMode: restMode,
          fixedRestWeekdays: fixedRestWeekdays,
          allowedRestDays: allowedRestDays,
        );

        final finishDate = schedules.last.date;
        final durationDaysActual = getDaysDifference(cleanStartDate, finishDate) + 1;
        final initialRemainingRestDays = restMode == RestMode.fixed
            ? 0
            : _schedulingService.getWeeklyAllocation(
                totalRestDays: allowedRestDays,
                durationDays: durationDaysActual,
                week: 1,
              );

        final project = ProjectModel(
          id: projectId,
          name: name,
          description: description,
          status: cleanStartDate.isAfter(cleanToday)
              ? ProjectStatus.upcoming
              : ProjectStatus.active,
          projectType: ProjectType.fixed,
          targetWords: targetWords,
          writtenWords: 0,
          remainingWords: targetWords,
          dailyWordTarget: dailyWordTarget,
          backlogWords: 0,
          startDate: cleanStartDate,
          expectedFinishDate: finishDate,
          restMode: restMode,
          allowedRestDays: allowedRestDays,
          remainingRestDays: initialRemainingRestDays,
          projectStreak: 0,
          longestProjectStreak: 0,
          currentWeek: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImagePath: coverImagePath,
          coverType: coverType,
          ongoingStyle: 'daily',
          writingSession: writingSession,
        );

        await _projectRepo.insertProject(project);
        await _scheduleRepo.insertSchedules(schedules);
      } else {
        final project = ProjectModel(
          id: projectId,
          name: name,
          description: description,
          status: cleanStartDate.isAfter(cleanToday)
              ? ProjectStatus.upcoming
              : ProjectStatus.active,
          projectType: ProjectType.ongoing,
          targetWords: 0,
          writtenWords: 0,
          remainingWords: 0,
          dailyWordTarget: dailyWordTarget,
          backlogWords: 0,
          startDate: cleanStartDate,
          expectedFinishDate: cleanStartDate,
          restMode: RestMode.flexible,
          allowedRestDays: 0,
          remainingRestDays: 0,
          projectStreak: 0,
          longestProjectStreak: 0,
          currentWeek: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImagePath: coverImagePath,
          coverType: coverType,
          ongoingStyle: ongoingStyle,
          writingSession: writingSession,
        );

        await _projectRepo.insertProject(project);

        if (cleanToday.isAtSameMomentAs(cleanStartDate) || cleanToday.isAfter(cleanStartDate)) {
          final List<ScheduleModel> initialTasks = [];
          var tempDate = cleanStartDate;
          while (tempDate.isBefore(cleanToday)) {
            initialTasks.add(ScheduleModel(
              id: uuid.v4(),
              projectId: projectId,
              date: tempDate,
              plannedWords: 0,
              isRestDay: true,
              automaticRestDay: true,
              completed: false,
              locked: true,
            ));
            tempDate = tempDate.add(const Duration(days: 1));
          }
          initialTasks.add(ScheduleModel(
            id: uuid.v4(),
            projectId: projectId,
            date: cleanToday,
            plannedWords: dailyWordTarget,
            isRestDay: false,
            completed: false,
            automaticRestDay: false,
            locked: false,
          ));
          await _scheduleRepo.insertSchedules(initialTasks);
        }
      }

      await loadProjects();
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await cleanupOrphanedCovers();
      return null;
    } catch (e) {
      return 'Failed to save project: $e';
    }
  }

  void _invalidateAllDependentProviders() {
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(homeEncouragementProvider);
    _ref.invalidate(homeQuoteProvider);
  }

  Future<void> cleanupOrphanedCovers() async {
    try {
      final list = await _projectRepo.getAllProjects();
      final activePaths = list
          .where((p) => p.coverType == 'uploaded' && p.coverImagePath != null)
          .map((p) => p.coverImagePath!)
          .toSet();

      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();
      for (final entity in files) {
        if (entity is File) {
          final filename = entity.path.split('/').last.split('\\').last;
          if (filename.startsWith('cover_') && !activePaths.contains(entity.path)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> deleteProject(String id) async {
    try {
      // Optimistic UI update: immediately remove project from memory
      if (state is AsyncData<List<ProjectModel>>) {
        final currentList = state.value ?? [];
        final newList = currentList.where((p) => p.id != id).toList();
        state = AsyncValue.data(newList);
      }

      final db = _ref.read(dbProvider);
      await db.transaction(() async {
        await _projectRepo.deleteProject(id);
        await _scheduleRepo.deleteSchedulesForProject(id);
        await _dailyLogRepo.deleteLogsForProject(id);
      });
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await loadProjects(silent: true);
      await cleanupOrphanedCovers();
    } catch (_) {}
  }

  Future<void> pauseProject(String id) async {
    try {
      // Optimistic UI update: immediately mark project as paused in memory
      if (state is AsyncData<List<ProjectModel>>) {
        final currentList = state.value ?? [];
        final newList = currentList.map((p) => p.id == id ? p.copyWith(status: ProjectStatus.paused) : p).toList();
        state = AsyncValue.data(newList);
      }

      final project = await _projectRepo.getProjectById(id);
      if (project != null && project.status == ProjectStatus.active) {
        final updated = project.copyWith(
          status: ProjectStatus.paused,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updated);
        await _statsRepo.recalculateStatistics();
        _invalidateAllDependentProviders();
        await loadProjects(silent: true);
      }
    } catch (_) {}
  }

  Future<void> resumeProject(String id) async {
    try {
      // Optimistic UI update: immediately mark project as active in memory
      if (state is AsyncData<List<ProjectModel>>) {
        final currentList = state.value ?? [];
        final newList = currentList.map((p) => p.id == id ? p.copyWith(status: ProjectStatus.active) : p).toList();
        state = AsyncValue.data(newList);
      }

      final project = await _projectRepo.getProjectById(id);
      if (project != null && project.status == ProjectStatus.paused) {
        final updated = project.copyWith(
          status: ProjectStatus.active,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updated);
        await _statsRepo.recalculateStatistics();
        _invalidateAllDependentProviders();
        await loadProjects(silent: true);
      }
    } catch (_) {}
  }

  Future<void> updateProject(ProjectModel updated) async {
    try {
      // Optimistic UI update: immediately replace project in memory
      if (state is AsyncData<List<ProjectModel>>) {
        final currentList = state.value ?? [];
        final newList = currentList.map((p) => p.id == updated.id ? updated : p).toList();
        state = AsyncValue.data(newList);
      }

      await _projectRepo.updateProject(updated);
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await loadProjects(silent: true);
      await cleanupOrphanedCovers();
    } catch (_) {}
  }

  Future<String?> convertDayToRestDay(ProjectModel project, ScheduleModel todaySchedule) async {
    try {
      final today = getLogicalToday();
      
      if (project.projectType == ProjectType.ongoing) {
        final updatedTodaySchedule = todaySchedule.copyWith(
          isRestDay: true,
          plannedWords: 0,
          locked: true,
          completed: true,
          automaticRestDay: false,
        );

        final db = _ref.read(dbProvider);
        await db.transaction(() async {
          await _scheduleRepo.updateSchedule(updatedTodaySchedule);
        });

        await _statsRepo.recalculateStatistics();
        _invalidateAllDependentProviders();
        await loadProjects(silent: true);
        return null;
      }

      // 1. Get all schedules for the project
      final schedules = await _scheduleRepo.getSchedulesForProject(project.id);
      
      // Check rest day cooldown rule: rest days must be separated by at least 2 writing days
      if (!_schedulingService.isRestDayAllowed(schedules: schedules, targetDate: todaySchedule.date)) {
        return 'Rest days must be separated by at least 2 writing days to maintain momentum.';
      }

      // 2. Filter future schedules starting from today (unlocked)
      final cleanToday = DateTime(today.year, today.month, today.day);
      final futureSchedules = schedules
          .where((s) => !s.locked && (s.date.isAfter(cleanToday) || s.date.isAtSameMomentAs(cleanToday)))
          .toList();
          
      // Calculate total planned words from unlocked future schedules
      final totalFuturePlannedWords = futureSchedules.fold<int>(0, (sum, s) => sum + s.plannedWords);

      // 3. Update today's schedule row (Rest Day, 0 planned words, locked)
      final updatedTodaySchedule = todaySchedule.copyWith(
        isRestDay: true,
        plannedWords: 0,
        locked: true,
        completed: false,
      );

      // Create a temporary list replacing today's schedule
      final tempSchedules = schedules.map((s) => s.id == todaySchedule.id ? updatedTodaySchedule : s).toList();

      // 4. Recalculate schedules from tomorrow onwards
      final tomorrow = cleanToday.add(const Duration(days: 1));
      
      // Count rest days used in history and today
      final restDaysUsed = tempSchedules.where((s) => (s.isRestDay || s.automaticRestDay) && (s.locked || s.date.isBefore(tomorrow))).length;

      final recalculatedSchedules = _schedulingService.recalculateFutureSchedule(
        existingSchedules: tempSchedules,
        recalculateFromDate: tomorrow,
        newDailyTarget: project.dailyWordTarget,
        totalRemainingWords: totalFuturePlannedWords,
        fixedRestWeekdays: const [],
        restMode: project.restMode,
        allowedRestDaysBudget: project.allowedRestDays,
        restDaysUsed: restDaysUsed,
      );

      // 5. Update schedules and project in a database transaction
      final db = _ref.read(dbProvider);
      await db.transaction(() async {
        for (final s in recalculatedSchedules) {
          await _scheduleRepo.updateSchedule(s);
        }
        
        final updatedProject = project.copyWith(
          remainingRestDays: project.remainingRestDays - 1 < 0 ? 0 : project.remainingRestDays - 1,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updatedProject);
      });

      // 6. Recalculate statistics
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await loadProjects(silent: true);
      return null;
    } catch (e, st) {
      debugPrint('Error converting day to rest day: $e\n$st');
      return 'Error occurred: $e';
    }
  }
}


final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>((ref) {
  return ProjectsNotifier(
    ref.watch(projectRepositoryProvider),
    ref.watch(schedulingServiceProvider),
    ref.watch(scheduleRepositoryProvider),
    ref.watch(ongoingSyncServiceProvider),
    ref.watch(dailyLogRepositoryProvider),
    ref.watch(statisticsRepositoryProvider),
    ref,
  );
});

// Settings Notifier
class SettingsNotifier extends StateNotifier<AsyncValue<SettingsModel>> {
  final SettingsRepository _settingsRepo;
  final Ref _ref;

  SettingsNotifier(this._settingsRepo, this._ref) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _settingsRepo.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTheme(String theme) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(theme: theme);
      await _settingsRepo.updateSettings(updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> toggleNotifications(bool val) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(notifications: val);
      await _settingsRepo.updateSettings(updated);
      state = AsyncValue.data(updated);
      await _ref.read(projectsProvider.notifier).loadProjects(silent: true);
    }
  }

  Future<void> toggleDailyQuotes(bool val) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(dailyQuotes: val);
      await _settingsRepo.updateSettings(updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> toggleVibration(bool val) async {
    final current = state.value;
    if (current != null) {
      final updated = current.copyWith(vibration: val);
      await _settingsRepo.updateSettings(updated);
      state = AsyncValue.data(updated);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsModel>>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider), ref);
});

// Statistics Provider
final statisticsProvider = FutureProvider<StatisticsModel>((ref) async {
  return ref.watch(statisticsRepositoryProvider).getStatistics();
});

// Contextual Encouragement & Quote Provider
final homeEncouragementProvider =
    FutureProvider.family<List<String>, String?>((ref, projectId) async {
  return ref.watch(encouragementServiceProvider).getContextualEncouragement(projectId);
});

final homeQuoteProvider =
    FutureProvider.family<QuoteModel?, String?>((ref, projectId) async {
  return ref.watch(encouragementServiceProvider).getQuoteForUser(projectId);
});

// Today Tasks Provider (Cached and auto-updating)
final todayTasksProvider = FutureProvider<List<TodayWritingTask>>((ref) async {
  final projectsAsync = ref.watch(projectsProvider);
  final projects = projectsAsync.value ?? [];
  final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();

  final schedRepo = ref.watch(scheduleRepositoryProvider);
  final logRepo = ref.watch(dailyLogRepositoryProvider);

  final List<TodayWritingTask> tasks = [];
  for (final p in activeProjects) {
    final schedules = await schedRepo.getSchedulesForProject(p.id);
    final projectToday = getLogicalTodayForProject(project: p, schedules: schedules);
    final cleanProjectToday = DateTime(projectToday.year, projectToday.month, projectToday.day);

    final sched = await schedRepo.getScheduleForDate(p.id, cleanProjectToday);
    if (sched != null) {
      final log = await logRepo.getLogForDate(p.id, cleanProjectToday);
      final logs = await logRepo.getLogsForProject(p.id);
      final successfulLogs = logs.where((l) => l.actualWords > 0).toList();
      DateTime? lastSuccessfulLogDate;
      if (successfulLogs.isNotEmpty) {
        lastSuccessfulLogDate = successfulLogs.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
      }

      tasks.add(TodayWritingTask(
        project: p,
        schedule: sched,
        log: log,
        lastSuccessfulLogDate: lastSuccessfulLogDate,
      ));
    }
  }
  return tasks;
});
