import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/connection/native.dart'
    if (dart.library.html) '../database/connection/web.dart' as native;
import '../models/project.dart';
import '../models/schedule.dart';

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

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final list = await _projectRepo.getAllProjects();
      final active = list.where((p) => p.status == ProjectStatus.active).toList();
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

      final updatedList = await _projectRepo.getAllProjects();
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
      final today = DateTime.now();
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
          remainingRestDays: allowedRestDays,
          projectStreak: 0,
          longestProjectStreak: 0,
          currentWeek: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImagePath: coverImagePath,
          coverType: coverType,
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
      final db = _ref.read(dbProvider);
      await db.transaction(() async {
        await _projectRepo.deleteProject(id);
        await _scheduleRepo.deleteSchedulesForProject(id);
        await _dailyLogRepo.deleteLogsForProject(id);
      });
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await loadProjects();
      await cleanupOrphanedCovers();
    } catch (_) {}
  }

  Future<void> pauseProject(String id) async {
    try {
      final project = await _projectRepo.getProjectById(id);
      if (project != null && project.status == ProjectStatus.active) {
        final updated = project.copyWith(
          status: ProjectStatus.paused,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updated);
        await loadProjects();
        await _statsRepo.recalculateStatistics();
        _invalidateAllDependentProviders();
      }
    } catch (_) {}
  }

  Future<void> resumeProject(String id) async {
    try {
      final project = await _projectRepo.getProjectById(id);
      if (project != null && project.status == ProjectStatus.paused) {
        final updated = project.copyWith(
          status: ProjectStatus.active,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updated);
        await loadProjects();
        await _statsRepo.recalculateStatistics();
        _invalidateAllDependentProviders();
      }
    } catch (_) {}
  }

  Future<void> updateProject(ProjectModel updated) async {
    try {
      await _projectRepo.updateProject(updated);
      await loadProjects();
      await _statsRepo.recalculateStatistics();
      _invalidateAllDependentProviders();
      await cleanupOrphanedCovers();
    } catch (_) {}
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

  SettingsNotifier(this._settingsRepo) : super(const AsyncValue.loading()) {
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
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
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
