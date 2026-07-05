import 'package:flutter_test/flutter_test.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/services/logging_service.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/shared/providers.dart';
import '../lib/services/ongoing_sync_service.dart';

// --- FAKE IN-MEMORY REPOSITORIES ---

class FakeProjectRepository implements ProjectRepository {
  final Map<String, ProjectModel> db = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ProjectModel?> getProjectById(String id) async => db[id];

  @override
  Future<void> updateProject(ProjectModel project) async {
    db[project.id] = project;
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async => db.values.toList();
}

class FakeScheduleRepository implements ScheduleRepository {
  final List<ScheduleModel> db = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ScheduleModel?> getScheduleForDate(String projectId, DateTime date) async {
    try {
      return db.firstWhere((s) => s.projectId == projectId && s.date.year == date.year && s.date.month == date.month && s.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ScheduleModel>> getSchedulesForProject(String projectId) async {
    return db.where((s) => s.projectId == projectId).toList();
  }

  @override
  Future<void> insertSchedules(List<ScheduleModel> schedules) async {
    for (final s in schedules) {
      db.removeWhere((x) => x.id == s.id);
      db.add(s);
    }
  }

  @override
  Future<void> updateSchedule(ScheduleModel schedule) async {
    final idx = db.indexWhere((s) => s.id == schedule.id);
    if (idx != -1) {
      db[idx] = schedule;
    }
  }
}

class FakeDailyLogRepository implements DailyLogRepository {
  final List<DailyLogModel> db = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DailyLogModel?> getLogForDate(String projectId, DateTime date) async {
    try {
      return db.firstWhere((l) => l.projectId == projectId && l.date.year == date.year && l.date.month == date.month && l.date.day == date.day);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DailyLogModel>> getLogsForProject(String projectId) async {
    return db.where((l) => l.projectId == projectId).toList();
  }

  @override
  Future<void> insertLog(DailyLogModel log) async {
    db.removeWhere((l) => l.id == log.id);
    db.add(log);
  }
}

class FakeStatisticsRepository implements StatisticsRepository {
  StatisticsModel stats = const StatisticsModel(
    id: 'global_stats',
    lifetimeWords: 0,
    averageWordsPerDay: 0.0,
    currentGlobalStreak: 0,
    longestGlobalStreak: 0,
    projectsCompleted: 0,
    writingDays: 0,
    restDaysUsed: 0,
    currentBacklog: 0,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<StatisticsModel> getStatistics() async => stats;

  @override
  Future<void> updateStatistics(StatisticsModel newStats) async {
    stats = newStats;
  }

  @override
  Future<void> recalculateStatistics() async {}
}

// --- MAIN UNIT TESTS ---

void main() {
  late FakeProjectRepository projectRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeDailyLogRepository logRepo;
  late FakeStatisticsRepository statsRepo;
  late LoggingService loggingService;

  final today = DateTime.now();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    projectRepo = FakeProjectRepository();
    scheduleRepo = FakeScheduleRepository();
    logRepo = FakeDailyLogRepository();
    statsRepo = FakeStatisticsRepository();

    loggingService = LoggingService(
      projectRepo,
      scheduleRepo,
      logRepo,
      statsRepo,
    );

    // Setup default fake project
    projectRepo.db['p1'] = ProjectModel(
      id: 'p1', name: 'Book 1', status: ProjectStatus.active,
      targetWords: 10000, writtenWords: 0, remainingWords: 10000,
      dailyWordTarget: 500, backlogWords: 0, startDate: cleanToday,
      expectedFinishDate: cleanToday.add(const Duration(days: 20)),
      restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
      projectStreak: 0, longestProjectStreak: 0, currentWeek: 1,
      createdAt: cleanToday, updatedAt: cleanToday,
    );
  });

  group('LoggingService - Logging Actions', () {
    test('logging matches target: marks completed and locks schedule', () async {
      // 1. Insert schedule row
      final sched = ScheduleModel(
        id: 's1', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // 2. Log exact words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 500);

      // 3. Verify
      final updatedSched = await scheduleRepo.getScheduleForDate('p1', cleanToday);
      expect(updatedSched?.completed, isTrue);
      expect(updatedSched?.locked, isTrue);

      final updatedProject = await projectRepo.getProjectById('p1');
      expect(updatedProject?.writtenWords, 500);
      expect(updatedProject?.remainingWords, 9500);
      expect(updatedProject?.projectStreak, 1);
    });

    test('logging under target: does not create backlog today, creates backlog after rollover', () async {
      final sched = ScheduleModel(
        id: 's1', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // Log only 200 words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 200);

      final updatedProjectToday = await projectRepo.getProjectById('p1');
      expect(updatedProjectToday?.writtenWords, 200);
      expect(updatedProjectToday?.backlogWords, 0); // No backlog generated today!
      expect(updatedProjectToday?.projectStreak, 0); // Streak reset

      // Simulate day rollover: move the schedule and log to yesterday (1 day ago)
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      
      final idxSched = scheduleRepo.db.indexWhere((s) => s.id == 's1');
      if (idxSched != -1) {
        scheduleRepo.db[idxSched] = scheduleRepo.db[idxSched].copyWith(
          date: yesterday,
        );
      }
      
      final log = await logRepo.getLogForDate('p1', cleanToday);
      if (log != null) {
        final idxLog = logRepo.db.indexWhere((l) => l.id == log.id);
        if (idxLog != -1) {
          logRepo.db[idxLog] = logRepo.db[idxLog].copyWith(
            date: yesterday,
            loggedAt: yesterday,
          );
        }
      }

      // Run sync service to catch up and calculate backlog
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(projectRepo),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
          dailyLogRepositoryProvider.overrideWithValue(logRepo),
        ],
      );
      final syncService = container.read(ongoingSyncServiceProvider);
      
      final project = await projectRepo.getProjectById('p1');
      if (project != null) {
        await syncService.syncFixedGoalBacklogs([project]);
      }

      final updatedProjectRollover = await projectRepo.getProjectById('p1');
      expect(updatedProjectRollover?.backlogWords, 300); // 300 words added to backlog after rollover!
    });

    test('logging over target: carry-forward saves to pendingCarryForward and does not modify future targets', () async {
      // Today (planned 500)
      final schedToday = ScheduleModel(
        id: 's_today', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      // Tomorrow (planned 500)
      final schedTomorrow = ScheduleModel(
        id: 's_tomorrow', projectId: 'p1', date: cleanToday.add(const Duration(days: 1)), plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([schedToday, schedTomorrow]);

      // Log 800 words (300 excess words)
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 800);

      // Verify today is completed
      final updatedToday = await scheduleRepo.getScheduleForDate('p1', cleanToday);
      expect(updatedToday?.completed, isTrue);

      // Verify tomorrow is NOT reduced (still 500)
      final updatedTomorrow = await scheduleRepo.getScheduleForDate('p1', cleanToday.add(const Duration(days: 1)));
      expect(updatedTomorrow?.plannedWords, 500);

      // Verify project has 300 words pending carry forward
      final updatedProject = await projectRepo.getProjectById('p1');
      expect(updatedProject?.pendingCarryForward, 300);
    });

    test('logging multiple times in a single day updates the log and does not double-increment streak', () async {
      // 1. Setup schedule row
      final sched = ScheduleModel(
        id: 's_multi', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // 2. Log first time (200 words, under target)
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 200);
      
      var project = await projectRepo.getProjectById('p1');
      expect(project?.writtenWords, 200);
      expect(project?.projectStreak, 0);

      // 3. Log second time (300 words, meets target of 500 total)
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 300);
      
      project = await projectRepo.getProjectById('p1');
      expect(project?.writtenWords, 500);
      expect(project?.projectStreak, 1);

      // 4. Log third time (100 words, over target to 600 total)
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 100);
      
      project = await projectRepo.getProjectById('p1');
      expect(project?.writtenWords, 600);
      expect(project?.projectStreak, 1); // Streak should remain 1, not 2
    });

    test('logging is additive by default', () async {
      final sched = ScheduleModel(
        id: 's_add', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // Log 200 words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 200);
      
      // Log another 150 words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 150);

      final updatedProject = await projectRepo.getProjectById('p1');
      expect(updatedProject?.writtenWords, 350); // accumulated!
    });

    test('logging with isAdditive: false overrides progress', () async {
      final sched = ScheduleModel(
        id: 's_override', projectId: 'p1', date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // Log 200 words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 200);
      
      // Log edit/override to 150 words
      await loggingService.logWords(projectId: 'p1', date: cleanToday, actualWords: 150, isAdditive: false);

      final updatedProject = await projectRepo.getProjectById('p1');
      expect(updatedProject?.writtenWords, 150); // overridden!
    });
  });
}
