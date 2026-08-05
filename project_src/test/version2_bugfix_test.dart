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
import '../lib/services/ongoing_sync_service.dart';
import '../lib/services/project_lifecycle_service.dart';
import '../lib/shared/providers.dart';
import '../lib/shared/date_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late StatisticsRepository statsRepo;
  late OngoingSyncService syncService;
  late ProjectLifecycleService lifecycleService;
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

    syncService = container.read(ongoingSyncServiceProvider);
    lifecycleService = container.read(projectLifecycleServiceProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Version 2 Stabilization Tests', () {
    test('Ongoing Sync Service generates schedules up to Sunday of current week', () async {
      final projectId = 'p_ongoing_sync';
      final project = ProjectModel(
        id: projectId,
        name: 'Ongoing Sync Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 3)),
        expectedFinishDate: cleanToday.add(const Duration(days: 30)),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      await syncService.syncOngoingSchedules([project]);

      // Calculate Sunday of current week
      final int daysToSunday = DateTime.sunday - cleanToday.weekday;
      final sunday = cleanToday.add(Duration(days: daysToSunday));

      final schedules = await scheduleRepo.getSchedulesForProject(projectId);
      expect(schedules.isNotEmpty, isTrue);

      final hasSundaySchedule = schedules.any((s) =>
          s.date.year == sunday.year &&
          s.date.month == sunday.month &&
          s.date.day == sunday.day);
      expect(hasSundaySchedule, isTrue);
    });

    test('Project Lifecycle Service automatically pauses inactive projects', () async {
      final projectId = 'p_inactive';
      final project = ProjectModel(
        id: projectId,
        name: 'Inactive Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 10)),
        expectedFinishDate: cleanToday.add(const Duration(days: 10)),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: cleanToday.subtract(const Duration(days: 10)),
        updatedAt: cleanToday.subtract(const Duration(days: 10)),
      );
      await projectRepo.insertProject(project);

      // Check and run automatic pause detection
      await lifecycleService.checkAndPauseInactiveProjects([project]);

      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject, isNotNull);
      expect(updatedProject!.status, equals(ProjectStatus.paused));
    });

    test('Statistics Repository rest days and streaks recalculate using unique calendar dates', () async {
      final p1 = 'p_streak_1';
      final p2 = 'p_streak_2';

      await projectRepo.insertProject(ProjectModel(
        id: p1,
        name: 'Book 1',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 1000,
        remainingWords: 9000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 10)),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await projectRepo.insertProject(ProjectModel(
        id: p2,
        name: 'Book 2',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 1000,
        remainingWords: 9000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 10)),
        restMode: RestMode.flexible,
        allowedRestDays: 7,
        remainingRestDays: 7,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final day1 = cleanToday.subtract(const Duration(days: 2));
      final day2 = cleanToday.subtract(const Duration(days: 1));

      // Day 1: Both projects rest -> This is a global rest day!
      await scheduleRepo.insertSchedules([
        ScheduleModel(id: 's1_1', projectId: p1, date: day1, plannedWords: 0, isRestDay: true, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's2_1', projectId: p2, date: day1, plannedWords: 0, isRestDay: true, completed: true, automaticRestDay: false, locked: true),
      ]);

      // Day 2: Project 1 completes target, Project 2 rests -> Streak continues (since Day 2 is not a rest day, but target is met where scheduled)
      await scheduleRepo.insertSchedules([
        ScheduleModel(id: 's1_2', projectId: p1, date: day2, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's2_2', projectId: p2, date: day2, plannedWords: 0, isRestDay: true, completed: true, automaticRestDay: false, locked: true),
      ]);
      await dailyLogRepo.insertLog(DailyLogModel(id: 'l1_2', projectId: p1, date: day2, plannedWords: 500, actualWords: 500, carryForwardWords: 0, backlogCreated: 0, completed: true, loggedAt: day2));

      final stats = await statsRepo.getStatistics();
      expect(stats.restDaysUsed, equals(1)); // Day 1 was a global rest day, Day 2 was not since Book 1 had a writing schedule.
      expect(stats.currentGlobalStreak, equals(1)); // Day 2 completed target, Day 1 skipped as rest.
    });

    test('Rest Day Cooldown prevents consecutive rest days within a 2-day window', () async {
      final projectId = 'p_cooldown';
      final project = ProjectModel(
        id: projectId,
        name: 'Cooldown Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 3)),
        expectedFinishDate: cleanToday.add(const Duration(days: 10)),
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

      final day1 = cleanToday.subtract(const Duration(days: 2));
      final day2 = cleanToday.subtract(const Duration(days: 1));
      final day3 = cleanToday;

      // Day 1 is a rest day
      final s1 = ScheduleModel(id: 's_c1', projectId: projectId, date: day1, plannedWords: 0, isRestDay: true, completed: true, automaticRestDay: false, locked: true);
      // Day 2 is a writing day
      final s2 = ScheduleModel(id: 's_c2', projectId: projectId, date: day2, plannedWords: 500, isRestDay: false, completed: false, automaticRestDay: false, locked: false);
      // Day 3 is today
      final s3 = ScheduleModel(id: 's_c3', projectId: projectId, date: day3, plannedWords: 500, isRestDay: false, completed: false, automaticRestDay: false, locked: false);

      await scheduleRepo.insertSchedules([s1, s2, s3]);

      // Check if rest day is allowed on Day 2:
      // Since Day 1 (1 day prior) is a rest day, it should be BLOCKED (false).
      final isAllowedOnDay2 = container.read(schedulingServiceProvider).isRestDayAllowed(schedules: [s1, s2, s3], targetDate: day2);
      expect(isAllowedOnDay2, isFalse);

      // Check if rest day is allowed on Day 3:
      // Day 1 (2 days prior) is a rest day, so it should also be BLOCKED (false) due to the 2-day gap requirement.
      final isAllowedOnDay3 = container.read(schedulingServiceProvider).isRestDayAllowed(schedules: [s1, s2, s3], targetDate: day3);
      expect(isAllowedOnDay3, isFalse);

      // Try calling convertDayToRestDay on Day 2 via the notifier
      final notifier = container.read(projectsProvider.notifier);
      await notifier.loadProjects();
      final errorResult = await notifier.convertDayToRestDay(project, s2);
      expect(errorResult, equals('Rest days must be separated by at least 2 writing days to maintain momentum.'));
    });

    test('Sprint Mode validation rules in SchedulingService', () {
      final service = container.read(schedulingServiceProvider);
      
      // Sprint mode with duration <= 10 days should succeed
      final errOk = service.validateInputs(
        targetWords: 5000,
        dailyWordTarget: 500,
        durationDays: 10,
        restMode: RestMode.sprint,
        allowedRestDays: 0,
      );
      expect(errOk, isNull);

      // Sprint mode with duration > 10 days should fail
      final errDuration = service.validateInputs(
        targetWords: 10000,
        dailyWordTarget: 500,
        durationDays: 11,
        restMode: RestMode.sprint,
        allowedRestDays: 0,
      );
      expect(errDuration, equals('Sprint Mode is only available for projects lasting 10 days or fewer.'));

      // Sprint mode with allowedRestDays > 0 should fail
      final errRestDays = service.validateInputs(
        targetWords: 5000,
        dailyWordTarget: 500,
        durationDays: 10,
        restMode: RestMode.sprint,
        allowedRestDays: 1,
      );
      expect(errRestDays, equals('Sprint Mode does not allow rest days.'));
    });

    test('Flexible and Adaptive Mode cannot have 0 rest days', () {
      final service = container.read(schedulingServiceProvider);
      
      final errFlex = service.validateInputs(
        targetWords: 5000,
        dailyWordTarget: 500,
        durationDays: 15,
        restMode: RestMode.flexible,
        allowedRestDays: 0,
      );
      expect(errFlex, equals('Flexible Rest Days must be at least 1.'));

      final errAdapt = service.validateInputs(
        targetWords: 5000,
        dailyWordTarget: 500,
        durationDays: 15,
        restMode: RestMode.adaptive,
        allowedRestDays: 0,
      );
      expect(errAdapt, equals('Adaptive Rest Days must be at least 1.'));
    });

    test('Sprint Mode active project generates Sprint encouragement message', () async {
      final project = ProjectModel(
        id: 'p_sprint_active',
        name: 'Sprint Challenge',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 2000,
        writtenWords: 0,
        remainingWords: 2000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 4)),
        restMode: RestMode.sprint,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      final encouragementService = container.read(encouragementServiceProvider);
      final messages = await encouragementService.getContextualEncouragement(null);
      
      final sprintEncouragements = [
        '🔥 Go on, champ. Fire on!',
        '⚡ Sprint mode activated. Keep pushing.',
        '🚀 No breaks. Finish strong.',
        '💪 One more session. You\'ve got this.',
        '✍️ Stay locked in. The finish line is close.',
      ];

      final hasSprintMessage = messages.any((msg) => sprintEncouragements.contains(msg));
      expect(hasSprintMessage, isTrue);
    });

    test('getLogicalTodayForProject resolves date correctly depending on completion', () {
      final project = ProjectModel(
        id: 'p_logical_check',
        name: 'Logical Check',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 5)),
        restMode: RestMode.flexible,
        allowedRestDays: 5,
        remainingRestDays: 5,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final yesterday = cleanToday.subtract(const Duration(days: 1));
      
      // Case 1: Yesterday schedule was completed -> should return calendarToday
      final sCompleted = ScheduleModel(
        id: 's_comp',
        projectId: project.id,
        date: yesterday,
        plannedWords: 500,
        isRestDay: false,
        completed: true,
        automaticRestDay: false,
        locked: false,
      );

      final resultCompleted = getLogicalTodayForProject(project: project, schedules: [sCompleted]);
      expect(resultCompleted, equals(cleanToday));

      // Case 2: Yesterday schedule was a rest day -> should return calendarToday
      final sRest = ScheduleModel(
        id: 's_rest',
        projectId: project.id,
        date: yesterday,
        plannedWords: 0,
        isRestDay: true,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );

      final resultRest = getLogicalTodayForProject(project: project, schedules: [sRest]);
      expect(resultRest, equals(cleanToday));
    });

    test('Upcoming project is automatically activated on loadProjects if start date is reached or passed', () async {
      final projectRepo = container.read(projectRepositoryProvider);
      final projectsNotifier = container.read(projectsProvider.notifier);

      final upcomingProject = ProjectModel(
        id: 'p_upcoming_activation_test',
        name: 'Upcoming Activation Test',
        status: ProjectStatus.upcoming,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)), // Start date was yesterday
        expectedFinishDate: cleanToday.add(const Duration(days: 5)),
        restMode: RestMode.flexible,
        allowedRestDays: 5,
        remainingRestDays: 5,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await projectRepo.insertProject(upcomingProject);

      // Verify it is currently upcoming in the DB
      final initialDbProject = await projectRepo.getProjectById(upcomingProject.id);
      expect(initialDbProject?.status, equals(ProjectStatus.upcoming));

      // Trigger loadProjects, which runs the auto-activation sweep
      await projectsNotifier.loadProjects();

      // Verify it is now active in the DB
      final activatedDbProject = await projectRepo.getProjectById(upcomingProject.id);
      expect(activatedDbProject?.status, equals(ProjectStatus.active));
    });

    test('Ongoing project in Rhythm Mode generates alternating schedule starting from start date', () async {
      final projectId = 'p_rhythm_sync';
      final monday = cleanToday.subtract(Duration(days: cleanToday.weekday - 1));
      final project = ProjectModel(
        id: projectId,
        name: 'Rhythm Habit Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        ongoingStyle: 'rhythm',
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: monday,
        expectedFinishDate: cleanToday.add(const Duration(days: 30)),
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      await syncService.syncOngoingSchedules([project]);

      final schedules = await scheduleRepo.getSchedulesForProject(projectId);
      expect(schedules.isNotEmpty, isTrue);

      // Verify alternating sequence
      for (final s in schedules) {
        final diff = getDaysDifference(project.startDate, s.date);
        final isRecovery = diff % 2 != 0;

        expect(s.isRecoveryDay, equals(isRecovery));

        if (isRecovery) {
          expect(s.plannedWords, equals(0));
          expect(s.completed, isTrue);
        } else {
          // If it is today or in the future, it should be a Writing Day
          if (s.date.isAfter(cleanToday) || s.date.isAtSameMomentAs(cleanToday)) {
            expect(s.plannedWords, equals(500));
            expect(s.isRestDay, isFalse);
          }
        }
      }
    });

    test('Logging words on a scheduled Recovery Day is blocked', () async {
      final loggingService = container.read(loggingServiceProvider);

      final projectId = 'p_rhythm_log_test';
      final project = ProjectModel(
        id: projectId,
        name: 'Rhythm Logging Block Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        ongoingStyle: 'rhythm',
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)), // Day 0 = yesterday, Day 1 = cleanToday (Recovery)
        expectedFinishDate: cleanToday.add(const Duration(days: 30)),
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      await syncService.syncOngoingSchedules([project]);

      // Verify that today (Day 1) is a Recovery Day
      final todaySched = await scheduleRepo.getScheduleForDate(projectId, cleanToday);
      expect(todaySched, isNotNull);
      expect(todaySched!.isRecoveryDay, isTrue);

      // Attempting to log words on today (Recovery Day) should fail
      expect(
        () => loggingService.logWords(
          projectId: projectId,
          date: cleanToday,
          actualWords: 200,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Past missed days are locked during backlog sync to prevent retroactive changes', () async {
      final cleanToday = DateTime(2026, 8, 5);
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final tomorrow = cleanToday.add(const Duration(days: 1));

      final project = ProjectModel(
        id: 'p_lock_test',
        name: 'Lock Test',
        projectType: ProjectType.fixed,
        targetWords: 3000,
        writtenWords: 0,
        remainingWords: 3000,
        dailyWordTarget: 1000,
        backlogWords: 0,
        startDate: yesterday,
        expectedFinishDate: tomorrow,
        status: ProjectStatus.active,
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

      // Create initial schedules
      final s1 = ScheduleModel(
        id: 's_yes',
        projectId: 'p_lock_test',
        date: yesterday,
        plannedWords: 1000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      final s2 = ScheduleModel(
        id: 's_tod',
        projectId: 'p_lock_test',
        date: cleanToday,
        plannedWords: 1000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      final s3 = ScheduleModel(
        id: 's_tom',
        projectId: 'p_lock_test',
        date: tomorrow,
        plannedWords: 1000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([s1, s2, s3]);

      // Run sync under Flexible mode
      await syncService.syncFixedGoalBacklogs([project]);

      // Verify that yesterday's schedule is now locked
      final s1Updated = await scheduleRepo.getScheduleForDate('p_lock_test', yesterday);
      expect(s1Updated, isNotNull);
      expect(s1Updated!.locked, isTrue);
      expect(s1Updated.isRestDay, isFalse);

      // Change project to Adaptive mode with budget
      final updatedProject = project.copyWith(
        restMode: RestMode.adaptive,
        remainingRestDays: 5,
        updatedAt: DateTime.now(),
      );
      await projectRepo.updateProject(updatedProject);

      // Run sync again under Adaptive mode
      await syncService.syncFixedGoalBacklogs([updatedProject]);

      // Verify that yesterday's schedule remained locked as a writing day and was NOT retroactively converted
      final s1Final = await scheduleRepo.getScheduleForDate('p_lock_test', yesterday);
      expect(s1Final, isNotNull);
      expect(s1Final!.locked, isTrue);
      expect(s1Final.isRestDay, isFalse);
      expect(s1Final.plannedWords, equals(1000));
    });

    test('Global streak ignores recovery days and requires all writing tasks today to be completed', () async {
      final p1 = 'p_streak_test_1';
      final p2 = 'p_streak_test_2';
      
      final project1 = ProjectModel(
        id: p1,
        name: 'Project 1',
        status: ProjectStatus.active,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 2000,
        backlogWords: 0,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedFinishDate: DateTime.now().add(const Duration(days: 5)),
        restMode: RestMode.flexible,
        allowedRestDays: 5,
        remainingRestDays: 5,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        projectType: ProjectType.fixed,
      );
      
      final project2 = ProjectModel(
        id: p2,
        name: 'Project 2 (Rhythm)',
        status: ProjectStatus.active,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 2000,
        backlogWords: 0,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        expectedFinishDate: DateTime.now().add(const Duration(days: 5)),
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        projectType: ProjectType.ongoing,
      );
      
      await projectRepo.insertProject(project1);
      await projectRepo.insertProject(project2);
      
      final today = getLogicalToday();
      final yesterday = today.subtract(const Duration(days: 1));
      
      final s1_y = ScheduleModel(
        id: 's1_y',
        projectId: p1,
        date: yesterday,
        plannedWords: 2000,
        isRestDay: false,
        automaticRestDay: false,
        isRecoveryDay: false,
        completed: false,
        locked: true,
      );
      
      final s1_t = ScheduleModel(
        id: 's1_t',
        projectId: p1,
        date: today,
        plannedWords: 2000,
        isRestDay: false,
        automaticRestDay: false,
        isRecoveryDay: false,
        completed: false,
        locked: false,
      );
      
      final s2_t = ScheduleModel(
        id: 's2_t',
        projectId: p2,
        date: today,
        plannedWords: 0,
        isRestDay: false,
        automaticRestDay: false,
        isRecoveryDay: true,
        completed: true,
        locked: false,
      );
      
      await scheduleRepo.insertSchedules([s1_y, s1_t, s2_t]);
      
      await statsRepo.recalculateStatistics();
      final stats = await statsRepo.getStatistics();
      
      expect(stats.currentGlobalStreak, equals(0));
      expect(stats.longestGlobalStreak, equals(0));
    });
  });
}
