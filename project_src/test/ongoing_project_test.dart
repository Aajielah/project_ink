import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/services/ongoing_sync_service.dart';
import '../lib/services/logging_service.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/shared/providers.dart';

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
}

// --- UNIT TESTS ---

void main() {
  late FakeProjectRepository projectRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeDailyLogRepository logRepo;
  late FakeStatisticsRepository statsRepo;
  
  late OngoingSyncService syncService;
  late LoggingService loggingService;
  late ProviderContainer container;

  final today = DateTime.now();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    projectRepo = FakeProjectRepository();
    scheduleRepo = FakeScheduleRepository();
    logRepo = FakeDailyLogRepository();
    statsRepo = FakeStatisticsRepository();

    container = ProviderContainer(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        projectRepositoryProvider.overrideWithValue(projectRepo),
        dailyLogRepositoryProvider.overrideWithValue(logRepo),
        statisticsRepositoryProvider.overrideWithValue(statsRepo),
      ],
    );

    syncService = container.read(ongoingSyncServiceProvider);
    loggingService = container.read(loggingServiceProvider);
  });

  tearDown(() {
    container.dispose();
  });

  group('Ongoing Project Sync & Catch-up Tests', () {
    test('new ongoing project gets today\'s schedule task only', () async {
      final project = ProjectModel(
        id: 'p_ongoing',
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: cleanToday,
        updatedAt: cleanToday,
      );
      projectRepo.db['p_ongoing'] = project;

      await syncService.syncOngoingSchedules([project]);

      final schedules = await scheduleRepo.getSchedulesForProject('p_ongoing');
      expect(schedules.length, 1);
      expect(schedules[0].date, cleanToday);
      expect(schedules[0].plannedWords, 500);
      expect(schedules[0].isRestDay, isFalse);
      expect(schedules[0].automaticRestDay, isFalse);
    });

    test('ongoing project catch-up fills intermediate days as automatic rest days', () async {
      final startDate = cleanToday.subtract(const Duration(days: 3));
      final project = ProjectModel(
        id: 'p_ongoing',
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 300,
        backlogWords: 0,
        startDate: startDate,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: startDate,
        updatedAt: startDate,
      );
      projectRepo.db['p_ongoing'] = project;

      // Pretend we synced on startDate (which inserted a schedule for startDate)
      final startSched = ScheduleModel(
        id: 's_start',
        projectId: 'p_ongoing',
        date: startDate,
        plannedWords: 300,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([startSched]);

      // Trigger sync today
      await syncService.syncOngoingSchedules([project]);

      final schedules = await scheduleRepo.getSchedulesForProject('p_ongoing');
      
      // Expected: startDate, startDate+1 (auto rest), startDate+2 (auto rest), today (target 300)
      expect(schedules.length, 4);

      final day1 = schedules.firstWhere((s) => s.date == startDate.add(const Duration(days: 1)));
      expect(day1.isRestDay, isTrue);
      expect(day1.automaticRestDay, isTrue);
      expect(day1.plannedWords, 0);

      final day2 = schedules.firstWhere((s) => s.date == startDate.add(const Duration(days: 2)));
      expect(day2.isRestDay, isTrue);
      expect(day2.automaticRestDay, isTrue);
      expect(day2.plannedWords, 0);

      final todaySched = schedules.firstWhere((s) => s.date == cleanToday);
      expect(todaySched.isRestDay, isFalse);
      expect(todaySched.plannedWords, 300);
    });
  });

  group('Ongoing Project Logging & Streaks Tests', () {
    test('logging less than daily target still completes and increments streak', () async {
      final project = ProjectModel(
        id: 'p_ongoing',
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: cleanToday,
        updatedAt: cleanToday,
      );
      projectRepo.db['p_ongoing'] = project;

      final sched = ScheduleModel(
        id: 's_today',
        projectId: 'p_ongoing',
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // Log 150 words (below target of 500)
      await loggingService.logWords(projectId: 'p_ongoing', date: cleanToday, actualWords: 150);

      final updatedProject = await projectRepo.getProjectById('p_ongoing');
      expect(updatedProject?.writtenWords, 150);
      expect(updatedProject?.backlogWords, 0); // No backlog for ongoing habits!
      expect(updatedProject?.projectStreak, 1); // Streak increments as long as actualWords > 0!

      final updatedSched = await scheduleRepo.getScheduleForDate('p_ongoing', cleanToday);
      expect(updatedSched?.completed, isTrue);
    });

    test('logging 0 words breaks the streak', () async {
      final project = ProjectModel(
        id: 'p_ongoing',
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 100,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 4, // existing streak
        longestProjectStreak: 4,
        currentWeek: 1,
        createdAt: cleanToday,
        updatedAt: cleanToday,
      );
      projectRepo.db['p_ongoing'] = project;

      final sched = ScheduleModel(
        id: 's_today',
        projectId: 'p_ongoing',
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([sched]);

      // Log 0 words today
      await loggingService.logWords(projectId: 'p_ongoing', date: cleanToday, actualWords: 0);

      final updatedProject = await projectRepo.getProjectById('p_ongoing');
      expect(updatedProject?.projectStreak, 0); // streak reset
    });
  });
}
