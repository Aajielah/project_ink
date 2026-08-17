import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/services/ongoing_sync_service.dart';
import '../lib/services/logging_service.dart';
import '../lib/services/scheduling_service.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/shared/providers.dart';
import '../lib/models/settings.dart';
import '../lib/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsModel _settings = const SettingsModel(
    id: 'settings',
    theme: 'system',
    notifications: true,
    dailyQuotes: true,
    backupReminder: true,
    vibration: true,
    streakShields: 2,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<SettingsModel> getSettings() async => _settings;

  @override
  Future<void> updateSettings(SettingsModel newSettings) async {
    _settings = newSettings;
  }
}

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
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
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
      expect(schedules.isNotEmpty, isTrue);
      final todaySched = schedules.firstWhere((s) => s.date.year == cleanToday.year && s.date.month == cleanToday.month && s.date.day == cleanToday.day);
      expect(todaySched.plannedWords, 500);
      expect(todaySched.isRestDay, isFalse);
      expect(todaySched.automaticRestDay, isFalse);
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
      
      // Expected: startDate, startDate+1 (auto rest), startDate+2 (auto rest), today (target 300), plus rest of current week
      expect(schedules.length, greaterThanOrEqualTo(4));

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
    test('logging less than daily target remains in progress and does not increment streak', () async {
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
      expect(updatedProject?.projectStreak, 0); // Streak remains 0

      final updatedSched = await scheduleRepo.getScheduleForDate('p_ongoing', cleanToday);
      expect(updatedSched?.completed, isFalse); // Remains incomplete/in progress!
    });

    test('logging daily target completes today and increments streak', () async {
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

      // Log 500 words (reaches target of 500)
      await loggingService.logWords(projectId: 'p_ongoing', date: cleanToday, actualWords: 500);

      final updatedProject = await projectRepo.getProjectById('p_ongoing');
      expect(updatedProject?.writtenWords, 500);
      expect(updatedProject?.backlogWords, 0);
      expect(updatedProject?.projectStreak, 1); // Streak increments on completion!

      final updatedSched = await scheduleRepo.getScheduleForDate('p_ongoing', cleanToday);
      expect(updatedSched?.completed, isTrue);
    });

    test('logging 0 words remains in progress and preserves streak', () async {
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
        startDate: cleanToday.subtract(const Duration(days: 4)),
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 4, // existing streak
        longestProjectStreak: 4,
        currentWeek: 1,
        createdAt: cleanToday.subtract(const Duration(days: 4)),
        updatedAt: cleanToday,
      );
      projectRepo.db['p_ongoing'] = project;

      // Seed 4 past completed days to justify the streak of 4
      for (int i = 1; i <= 4; i++) {
        final date = cleanToday.subtract(Duration(days: i));
        await scheduleRepo.insertSchedules([
          ScheduleModel(
            id: 's_past_$i',
            projectId: 'p_ongoing',
            date: date,
            plannedWords: 500,
            isRestDay: false,
            completed: true,
            automaticRestDay: false,
            locked: true,
          )
        ]);
        await logRepo.insertLog(
          DailyLogModel(
            id: 'l_past_$i',
            projectId: 'p_ongoing',
            scheduleId: 's_past_$i',
            date: date,
            plannedWords: 500,
            actualWords: 500,
            carryForwardWords: 0,
            backlogCreated: 0,
            completed: true,
            loggedAt: date,
          )
        );
      }

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
      expect(updatedProject?.projectStreak, 4); // streak preserved today since it's still ongoing!
    });

    test('ongoing project catch-up converts past incomplete days to Rest Days and preserves streak', () async {
      final startDate = cleanToday.subtract(const Duration(days: 2));
      final project = ProjectModel(
        id: 'p_ongoing',
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 150,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: startDate,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 3, // existing streak
        longestProjectStreak: 3,
        currentWeek: 1,
        createdAt: startDate,
        updatedAt: startDate,
      );
      projectRepo.db['p_ongoing'] = project;

      // Day 1 (yesterday): writing day, logged 150/500 (incomplete)
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final yesterdaySched = ScheduleModel(
        id: 's_yesterday',
        projectId: 'p_ongoing',
        date: yesterday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: true,
      );
      final yesterdayLog = DailyLogModel(
        id: 'l_yesterday',
        projectId: 'p_ongoing',
        scheduleId: 's_yesterday',
        date: yesterday,
        plannedWords: 500,
        actualWords: 150,
        carryForwardWords: 0,
        backlogCreated: 0,
        completed: false,
        loggedAt: yesterday,
      );
      await scheduleRepo.insertSchedules([yesterdaySched]);
      await logRepo.insertLog(yesterdayLog);

      // Trigger sync today
      await syncService.syncOngoingSchedules([project]);

      final updatedSched = await scheduleRepo.getScheduleForDate('p_ongoing', yesterday);
      expect(updatedSched?.isRestDay, isTrue);
      expect(updatedSched?.automaticRestDay, isTrue);
      expect(updatedSched?.plannedWords, 0);

      final updatedLog = await logRepo.getLogForDate('p_ongoing', yesterday);
      expect(updatedLog?.plannedWords, 0);
      expect(updatedLog?.backlogCreated, 0);
    });
  });

  group('Flexible and Adaptive Rest Days Tests', () {
    test('Adaptive projects automatically consume an available Rest Day and redistribute', () async {
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final tomorrow = cleanToday.add(const Duration(days: 1));

      final project = ProjectModel(
        id: 'p_adap_auto',
        name: 'Adaptive Auto Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 0,
        remainingWords: 1000,
        dailyWordTarget: 1000,
        backlogWords: 0,
        startDate: yesterday,
        expectedFinishDate: tomorrow,
        restMode: RestMode.adaptive,
        allowedRestDays: 2,
        remainingRestDays: 2,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: yesterday,
        updatedAt: yesterday,
      );
      projectRepo.db['p_adap_auto'] = project;

      final s1 = ScheduleModel(
        id: 's_yesterday',
        projectId: 'p_adap_auto',
        date: yesterday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      final s2 = ScheduleModel(
        id: 's_today',
        projectId: 'p_adap_auto',
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([s1, s2]);

      await syncService.syncFixedGoalBacklogs([project]);

      final updatedS1 = await scheduleRepo.getScheduleForDate('p_adap_auto', yesterday);
      expect(updatedS1?.isRestDay, isTrue);
      expect(updatedS1?.plannedWords, 0);
      expect(updatedS1?.locked, isTrue);
      expect(updatedS1?.automaticRestDay, isTrue);

      final updatedProj = await projectRepo.getProjectById('p_adap_auto');
      expect(updatedProj?.remainingRestDays, 1);
      expect(updatedProj?.backlogWords, 0);

      final updatedS2 = await scheduleRepo.getScheduleForDate('p_adap_auto', cleanToday);
      expect(updatedS2?.plannedWords, 1000);
    });

    test('Adaptive projects generate backlog if no Adaptive Rest Days remain', () async {
      final yesterday = cleanToday.subtract(const Duration(days: 1));

      final project = ProjectModel(
        id: 'p_adap_backlog',
        name: 'Adaptive Backlog Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 0,
        remainingWords: 1000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: yesterday,
        expectedFinishDate: cleanToday,
        restMode: RestMode.adaptive,
        allowedRestDays: 2,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: yesterday,
        updatedAt: yesterday,
      );
      projectRepo.db['p_adap_backlog'] = project;

      final s1 = ScheduleModel(
        id: 's_yesterday',
        projectId: 'p_adap_backlog',
        date: yesterday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([s1]);

      await syncService.syncFixedGoalBacklogs([project]);

      final updatedS1 = await scheduleRepo.getScheduleForDate('p_adap_backlog', yesterday);
      expect(updatedS1?.isRestDay, isFalse);

      final updatedProj = await projectRepo.getProjectById('p_adap_backlog');
      expect(updatedProj?.backlogWords, 500);
    });

    test('Flexible projects never automatically consume rest days on rollover and create backlog instead', () async {
      final yesterday = cleanToday.subtract(const Duration(days: 1));

      final project = ProjectModel(
        id: 'p_flex_rollover',
        name: 'Flex Rollover Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 0,
        remainingWords: 1000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: yesterday,
        expectedFinishDate: cleanToday,
        restMode: RestMode.flexible,
        allowedRestDays: 2,
        remainingRestDays: 2,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: yesterday,
        updatedAt: yesterday,
      );
      projectRepo.db['p_flex_rollover'] = project;

      final s1 = ScheduleModel(
        id: 's_yesterday',
        projectId: 'p_flex_rollover',
        date: yesterday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([s1]);

      await syncService.syncFixedGoalBacklogs([project]);

      final updatedS1 = await scheduleRepo.getScheduleForDate('p_flex_rollover', yesterday);
      expect(updatedS1?.isRestDay, isFalse);

      final updatedProj = await projectRepo.getProjectById('p_flex_rollover');
      expect(updatedProj?.backlogWords, 500);
      expect(updatedProj?.remainingRestDays, 2); // Budget untouched!
    });

    test('Changing from adaptive to flexible and vice versa recalculates remainingRestDays correctly', () {
      final startDate = cleanToday.subtract(const Duration(days: 7)); // start of week 1 (we are in week 2 now)
      final expectedFinish = cleanToday.add(const Duration(days: 7));

      // 1. Initial Project in Adaptive mode
      // Allowed rest days: 3 (1 per week)
      // Schedules has 1 rest day in Week 1, and 0 in Week 2 (which is cleanToday)
      final projectAdaptive = ProjectModel(
        id: 'p_transition',
        name: 'Transition Test',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 6000,
        writtenWords: 1000,
        remainingWords: 5000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: startDate,
        expectedFinishDate: expectedFinish,
        restMode: RestMode.adaptive,
        allowedRestDays: 3,
        remainingRestDays: 1, // 1 remaining for Week 2 (starts with 1, used 0)
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 2,
        createdAt: startDate,
        updatedAt: startDate,
      );

      final schedules = [
        ScheduleModel(
          id: 's_w1_1',
          projectId: 'p_transition',
          date: startDate,
          plannedWords: 0,
          isRestDay: true, // Rest day used in Week 1
          completed: false,
          automaticRestDay: true,
          locked: true,
        ),
        ScheduleModel(
          id: 's_w2_1',
          projectId: 'p_transition',
          date: cleanToday,
          plannedWords: 500,
          isRestDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        ),
      ];

      // Transitioning to Flexible Mode
      final tempFlexible = projectAdaptive.copyWith(
        restMode: RestMode.flexible,
      );

      final remainingFlexible = container.read(schedulingServiceProvider).getAvailableRestDays(
        project: tempFlexible,
        schedules: schedules,
        logicalToday: cleanToday,
      );

      // We expect:
      // totalAllocatedUpToNow for Week 2:
      // Week 1 allocation = 1
      // Week 2 allocation = 1
      // Total allocated = 2
      // Total used overall = 1 (s_w1_1)
      // So remaining for flexible = 2 - 1 = 1!
      expect(remainingFlexible, 1);

      // Now, let's suppose we are transitioning from a Flexible Project with overall budget 3, where we used 1 rest day.
      // Dynamic remaining flexible is 2 (total budget 3 - used 1 = 2).
      // We transition to Adaptive Mode:
      final projectFlexible = projectAdaptive.copyWith(
        restMode: RestMode.flexible,
        remainingRestDays: 2, // 3 allowed - 1 used = 2
      );

      final tempAdaptive = projectFlexible.copyWith(
        restMode: RestMode.adaptive,
      );

      final remainingAdaptive = container.read(schedulingServiceProvider).getAvailableRestDays(
        project: tempAdaptive,
        schedules: schedules,
        logicalToday: cleanToday,
      );

      // We expect:
      // Week 2 allocation = 1
      // Week 2 used = 0
      // So remaining adaptive = 1 - 0 = 1!
      expect(remainingAdaptive, 1);
    });
  });
}
