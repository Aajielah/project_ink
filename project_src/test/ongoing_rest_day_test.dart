import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/services/scheduling_service.dart';
import '../lib/shared/providers.dart';
import '../lib/shared/date_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late StatisticsRepository statsRepo;
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Ongoing Project Rest Day Logic', () {
    test('Ongoing project can always be marked as a rest day, bypasses validation, and does not create backlog', () async {
      final projectId = 'p_ongoing_1';
      final project = ProjectModel(
        id: projectId,
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 0,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 2)),
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

      final schedule = ScheduleModel(
        id: 's_ongoing_today',
        projectId: projectId,
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([schedule]);

      // Call conversion logic
      final notifier = container.read(projectsProvider.notifier);
      await notifier.convertDayToRestDay(project, schedule);

      // Verify the schedule state updates: isRestDay=true, completed=true, locked=true, automaticRestDay=false
      final updatedSchedule = await scheduleRepo.getScheduleForDate(projectId, cleanToday);
      expect(updatedSchedule, isNotNull);
      expect(updatedSchedule!.isRestDay, isTrue);
      expect(updatedSchedule.completed, isTrue);
      expect(updatedSchedule.locked, isTrue);
      expect(updatedSchedule.automaticRestDay, isFalse);

      // Verify no backlog is created
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject?.backlogWords, 0);

      // Verify available rest days returns high budget indicator
      final available = container.read(schedulingServiceProvider).getAvailableRestDays(
        project: project,
        schedules: [updatedSchedule],
        logicalToday: cleanToday,
      );
      expect(available, 9999);
    });

    test('Statistics correctly records ongoing rest days and preserves streaks', () async {
      final projectId = 'p_ongoing_stats';
      final project = ProjectModel(
        id: projectId,
        name: 'Ongoing Stats Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 500,
        remainingWords: 0,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)),
        expectedFinishDate: cleanToday.add(const Duration(days: 1)),
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

      // Day 1: Completed writing day
      final date1 = cleanToday.subtract(const Duration(days: 1));
      final s1 = ScheduleModel(
        id: 's_date1', projectId: projectId, date: date1, plannedWords: 500,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      // Day 2: Today (Rest Day)
      final sToday = ScheduleModel(
        id: 's_today', projectId: projectId, date: cleanToday, plannedWords: 500,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([s1, sToday]);

      await dailyLogRepo.insertLog(DailyLogModel(
        id: 'log1', projectId: projectId, scheduleId: 's_date1', date: date1,
        plannedWords: 500, actualWords: 500, carryForwardWords: 0, backlogCreated: 0, completed: true, loggedAt: date1,
      ));

      // Today is active and not finalized/locked, so yesterday's streak is preserved
      var stats = await statsRepo.getStatistics();
      expect(stats.currentGlobalStreak, 1);

      // Mark today as Rest Day
      final notifier = container.read(projectsProvider.notifier);
      await notifier.convertDayToRestDay(project, sToday);

      // Recalculate statistics
      stats = await statsRepo.getStatistics();

      // Rest Day preserves the streak (still 1)
      expect(stats.currentGlobalStreak, 1);
      // Rest Day is correctly recorded in statistics
      expect(stats.restDaysUsed, 1);
    });

    test('Fixed projects continue enforcing configured rest-day limits', () async {
      final projectId = 'p_fixed_limits';
      final project = ProjectModel(
        id: projectId,
        name: 'Fixed Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 0,
        remainingWords: 1000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 1)),
        restMode: RestMode.flexible,
        allowedRestDays: 0, // No rest days allowed
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      final s = ScheduleModel(
        id: 's_fixed_today',
        projectId: projectId,
        date: cleanToday,
        plannedWords: 500,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await scheduleRepo.insertSchedules([s]);

      final available = container.read(schedulingServiceProvider).getAvailableRestDays(
        project: project,
        schedules: [s],
        logicalToday: cleanToday,
      );
      // Available budget is 0
      expect(available, 0);
    });

    test('Sliding carry-forward credit: when a writing day with a carry-forward discount is manually converted to a rest day, the discount slides to the next active writing day', () async {
      final projectId = 'p_slide_carry_forward';
      final project = ProjectModel(
        id: projectId,
        name: 'Slide Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 201, // Today logged 201 words (1 word of excess)
        remainingWords: 799,
        dailyWordTarget: 200,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)),
        expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.flexible,
        allowedRestDays: 5,
        remainingRestDays: 5,
        projectStreak: 1,
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      // May 1st (yesterday) - Completed
      final date1 = cleanToday.subtract(const Duration(days: 1));
      final s1 = ScheduleModel(
        id: 's_date1', projectId: projectId, date: date1, plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );

      // May 2nd (today) - Has a carry-forward discount applied (target 199 instead of 200)
      final sToday = ScheduleModel(
        id: 's_today', projectId: projectId, date: cleanToday, plannedWords: 199,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );

      // May 3rd (tomorrow) - Standard target 200
      final dateTomorrow = cleanToday.add(const Duration(days: 1));
      final sTomorrow = ScheduleModel(
        id: 's_tomorrow', projectId: projectId, date: dateTomorrow, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );

      await scheduleRepo.insertSchedules([s1, sToday, sTomorrow]);

      // Call conversion logic for today (May 2nd)
      final notifier = container.read(projectsProvider.notifier);
      await notifier.convertDayToRestDay(project, sToday);

      // 1. Verify May 2nd became a rest day with 0 planned words
      final updatedTodaySchedule = await scheduleRepo.getScheduleForDate(projectId, cleanToday);
      expect(updatedTodaySchedule, isNotNull);
      expect(updatedTodaySchedule!.isRestDay, isTrue);
      expect(updatedTodaySchedule.plannedWords, 0);

      // 2. Verify project's pendingCarryForward has been successfully restored to the pool (set to 1)
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject, isNotNull);
      expect(updatedProject!.pendingCarryForward, 1);

      // Verify tomorrow's target remains standard (200) until tomorrow becomes today and the carry-forward is applied
      final updatedTomorrowSchedule = await scheduleRepo.getScheduleForDate(projectId, dateTomorrow);
      expect(updatedTomorrowSchedule, isNotNull);
      expect(updatedTomorrowSchedule!.plannedWords, 200);
    });
  });
}
