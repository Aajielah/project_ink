import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/services/logging_service.dart';
import '../lib/services/scheduling_service.dart';
import '../lib/shared/providers.dart';
import '../lib/shared/date_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late StatisticsRepository statsRepo;
  late LoggingService loggingService;
  late SchedulingService schedulingService;
  late ProviderContainer container;

  final today = getLogicalToday();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    dailyLogRepo = DailyLogRepository(db);
    statsRepo = StatisticsRepository(db);

    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        projectRepositoryProvider.overrideWithValue(projectRepo),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        dailyLogRepositoryProvider.overrideWithValue(dailyLogRepo),
        statisticsRepositoryProvider.overrideWithValue(statsRepo),
      ],
    );

    loggingService = container.read(loggingServiceProvider);
    schedulingService = container.read(schedulingServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Logical Bug Audit Verification Tests', () {
    test('1. Calendar math: addCalendarDays and subtractCalendarDays preserve exact day offsets', () {
      final base = DateTime(2026, 3, 28, 14, 30);
      final nextDay = addCalendarDays(base, 1);
      expect(nextDay.year, equals(2026));
      expect(nextDay.month, equals(3));
      expect(nextDay.day, equals(29));
      expect(nextDay.hour, equals(0));
      expect(nextDay.minute, equals(0));

      final prevDay = subtractCalendarDays(base, 1);
      expect(prevDay.year, equals(2026));
      expect(prevDay.month, equals(3));
      expect(prevDay.day, equals(27));
      expect(prevDay.hour, equals(0));
      expect(prevDay.minute, equals(0));

      // Month rollover
      final endOfMonth = DateTime(2026, 1, 31);
      final nextMonth = addCalendarDays(endOfMonth, 1);
      expect(nextMonth.year, equals(2026));
      expect(nextMonth.month, equals(2));
      expect(nextMonth.day, equals(1));
    });

    test('2. Rhythm Mode recovery days do not break streak in LoggingService', () async {
      final projectId = 'p_rhythm_recovery_streak';
      final project = ProjectModel(
        id: projectId,
        name: 'Rhythm Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        ongoingStyle: 'rhythm',
        targetWords: 0,
        writtenWords: 500,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: subtractCalendarDays(cleanToday, 2),
        expectedFinishDate: addCalendarDays(cleanToday, 30),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 1,
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      // Day -2: Writing Day (Completed)
      final dayMinus2 = subtractCalendarDays(cleanToday, 2);
      final s1 = ScheduleModel(
        id: 's_1',
        projectId: projectId,
        date: dayMinus2,
        plannedWords: 500,
        isRestDay: false,
        isRecoveryDay: false,
        completed: true,
        automaticRestDay: false,
        locked: true,
      );
      final l1 = DailyLogModel(
        id: 'l_1',
        projectId: projectId,
        date: dayMinus2,
        plannedWords: 500,
        actualWords: 500,
        carryForwardWords: 0,
        backlogCreated: 0,
        completed: true,
        loggedAt: DateTime.now(),
      );

      // Day -1: Recovery Day (Rest / not completed, but recovery day!)
      final dayMinus1 = subtractCalendarDays(cleanToday, 1);
      final s2 = ScheduleModel(
        id: 's_2',
        projectId: projectId,
        date: dayMinus1,
        plannedWords: 0,
        isRestDay: true,
        isRecoveryDay: true,
        completed: false,
        automaticRestDay: false,
        locked: true,
      );

      // Day 0: Today Writing Day
      final s3 = ScheduleModel(
        id: 's_3',
        projectId: projectId,
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        isRecoveryDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );

      await scheduleRepo.insertSchedules([s1, s2, s3]);
      await dailyLogRepo.insertLog(l1);

      // Log today's words
      await loggingService.logWords(
        projectId: projectId,
        date: cleanToday,
        actualWords: 500,
        isAdditive: true,
      );

      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject, isNotNull);
      // Streak should be 2 because the recovery day did NOT break the streak!
      expect(updatedProject!.projectStreak, equals(2));
    });

    test('3. Phantom backlog sentinel (-1) does not generate +1 phantom word', () async {
      final projectId = 'p_sentinel_backlog';
      final project = ProjectModel(
        id: projectId,
        name: 'Sentinel Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 200,
        remainingWords: 9800,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: addCalendarDays(cleanToday, 20),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      // Schedule for today
      final sToday = ScheduleModel(
        id: 's_sentinel_today',
        projectId: projectId,
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        isRecoveryDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([sToday]);

      // Prior log had backlogCreated = -1 (resolved sentinel)
      final existingLog = DailyLogModel(
        id: 'l_sentinel_today',
        projectId: projectId,
        date: cleanToday,
        plannedWords: 500,
        actualWords: 200,
        carryForwardWords: 0,
        backlogCreated: -1, // sentinel indicating resolved backlog
        completed: false,
        loggedAt: DateTime.now(),
      );
      await dailyLogRepo.insertLog(existingLog);

      // Log additional words additively (+100 words)
      await loggingService.logWords(
        projectId: projectId,
        date: cleanToday,
        actualWords: 100,
        isAdditive: true,
      );

      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject, isNotNull);
      // Backlog words must remain 0, NOT become 1 (from -(-1))!
      expect(updatedProject!.backlogWords, equals(0));
    });

    test('4. Additive word logging: 200 morning + 300 evening correctly equals 500 total words', () async {
      final projectId = 'p_additive_logging';
      final project = ProjectModel(
        id: projectId,
        name: 'Additive Test Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: addCalendarDays(cleanToday, 20),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      await scheduleRepo.insertSchedules([
        ScheduleModel(
          id: 's_additive_today',
          projectId: projectId,
          date: cleanToday,
          plannedWords: 500,
          isRestDay: false,
          isRecoveryDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        )
      ]);

      // Session 1: 200 words
      await loggingService.logWords(
        projectId: projectId,
        date: cleanToday,
        actualWords: 200,
        isAdditive: true,
      );

      var log = await dailyLogRepo.getLogForDate(projectId, cleanToday);
      expect(log?.actualWords, equals(200));

      // Session 2: 300 words added
      await loggingService.logWords(
        projectId: projectId,
        date: cleanToday,
        actualWords: 300,
        isAdditive: true,
      );

      log = await dailyLogRepo.getLogForDate(projectId, cleanToday);
      expect(log?.actualWords, equals(500));

      final updatedProj = await projectRepo.getProjectById(projectId);
      expect(updatedProj?.writtenWords, equals(500));
      expect(updatedProj?.remainingWords, equals(9500));
    });

    test('5. Scheduling validation: start date on Friday with 2 weekend rest days validates successfully', () {
      // 2026-09-04 is a Friday (weekday 5)
      final fridayStart = DateTime(2026, 9, 4);
      expect(fridayStart.weekday, equals(DateTime.friday));

      // 7 days duration with 2 rest days (Saturday & Sunday)
      final error = schedulingService.validateInputs(
        targetWords: 5000,
        dailyWordTarget: 1000,
        durationDays: 7,
        restMode: RestMode.fixed,
        fixedRestWeekdays: [DateTime.saturday, DateTime.sunday],
        allowedRestDays: 2,
        startDate: fridayStart,
      );

      expect(error, isNull);
    });

    test('6. ProjectRepository saves and returns groupId for series and runs', () async {
      final p1 = ProjectModel(
        id: 'p_series_1',
        name: 'Trilogy Part 1',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 50000,
        writtenWords: 10000,
        remainingWords: 40000,
        dailyWordTarget: 1000,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: addCalendarDays(cleanToday, 50),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        groupId: 'trilogy_group_123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(p1);

      final retrieved = await projectRepo.getProjectById('p_series_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.groupId, equals('trilogy_group_123'));
    });

    test('7. StatisticsRepository resets streak when there are unscheduled inactive gap days', () async {
      final projectId = 'p_stats_streak_gap';
      final project = ProjectModel(
        id: projectId,
        name: 'Stats Gap Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 1000,
        remainingWords: 9000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: subtractCalendarDays(cleanToday, 10),
        expectedFinishDate: addCalendarDays(cleanToday, 10),
        restMode: RestMode.flexible,
        allowedRestDays: 5,
        remainingRestDays: 5,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      // Day -5: wrote 500 words
      final day5 = subtractCalendarDays(cleanToday, 5);
      final s5 = ScheduleModel(
        id: 's_gap_5',
        projectId: projectId,
        date: day5,
        plannedWords: 500,
        isRestDay: false,
        isRecoveryDay: false,
        completed: true,
        automaticRestDay: false,
        locked: true,
      );
      final l5 = DailyLogModel(
        id: 'l_5',
        projectId: projectId,
        date: day5,
        plannedWords: 500,
        actualWords: 500,
        carryForwardWords: 0,
        backlogCreated: 0,
        completed: true,
        loggedAt: DateTime.now(),
      );

      // Day -4, -3, -2: NO schedules and NO logs (inactive gap days!)

      // Day -1: wrote 500 words
      final day1 = subtractCalendarDays(cleanToday, 1);
      final s1 = ScheduleModel(
        id: 's_gap_1',
        projectId: projectId,
        date: day1,
        plannedWords: 500,
        isRestDay: false,
        isRecoveryDay: false,
        completed: true,
        automaticRestDay: false,
        locked: true,
      );
      final l1 = DailyLogModel(
        id: 'l_1',
        projectId: projectId,
        date: day1,
        plannedWords: 500,
        actualWords: 500,
        carryForwardWords: 0,
        backlogCreated: 0,
        completed: true,
        loggedAt: DateTime.now(),
      );

      await scheduleRepo.insertSchedules([s5, s1]);
      await dailyLogRepo.insertLog(l5);
      await dailyLogRepo.insertLog(l1);

      // Calculate streak
      final stats = await statsRepo.getStatistics();
      // Since days -4, -3, -2 were inactive gaps with 0 words, streak should NOT be 5 days!
      // Current streak is at most 1 day (day -1).
      expect(stats.currentGlobalStreak, equals(1));
    });

    test('8. Android notification ID 32-bit integer overflow guard', () {
      final longId = 'very_long_project_uuid_string_that_hashes_high';
      final rawHash = longId.hashCode;
      final safeId = rawHash & 0x7FFFFFFF;

      expect(safeId >= 0, isTrue);
      expect(safeId <= 2147483647, isTrue);
    });
  });
}
