import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../database/connection/native.dart'
    if (dart.library.html) '../database/connection/web.dart' as native;
import '../models/project.dart';

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

  ProjectsNotifier(this._projectRepo, this._schedulingService, this._scheduleRepo)
      : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final list = await _projectRepo.getAllProjects();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> addProject({
    required String name,
    String? description,
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
    // 1. Validate
    final err = _schedulingService.validateInputs(
      targetWords: targetWords,
      dailyWordTarget: dailyWordTarget,
      durationDays: durationDays,
      restMode: restMode,
      fixedRestWeekdays: fixedRestWeekdays,
      allowedRestDays: allowedRestDays,
    );
    if (err != null) return err;

    try {
      final uuid = const Uuid();
      final projectId = uuid.v4();

      // 2. Generate initial schedule
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

      // Calculate finish date based on generated schedule dates
      final finishDate = schedules.last.date;

      // 3. Create project model
      final today = DateTime.now();
      final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final cleanToday = DateTime(today.year, today.month, today.day);

      final project = ProjectModel(
        id: projectId,
        name: name,
        description: description,
        status: cleanStartDate.isAfter(cleanToday)
            ? ProjectStatus.upcoming
            : ProjectStatus.active,
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

      // 4. Save to DB
      await _projectRepo.insertProject(project);
      await _scheduleRepo.insertSchedules(schedules);

      // 5. Reload state
      await loadProjects();
      return null; // success
    } catch (e) {
      return 'Failed to save project: $e';
    }
  }


  Future<void> deleteProject(String id) async {
    try {
      await _projectRepo.deleteProject(id);
      await loadProjects();
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
      }
    } catch (_) {}
  }

  Future<void> updateProject(ProjectModel updated) async {
    try {
      await _projectRepo.updateProject(updated);
      await loadProjects();
    } catch (_) {}
  }
}


final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>((ref) {
  return ProjectsNotifier(
    ref.watch(projectRepositoryProvider),
    ref.watch(schedulingServiceProvider),
    ref.watch(scheduleRepositoryProvider),
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
