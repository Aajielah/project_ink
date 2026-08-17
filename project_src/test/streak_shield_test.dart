import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/settings_repository.dart';
import '../lib/repositories/statistics_repository.dart';
import '../lib/services/ongoing_sync_service.dart';
import '../lib/shared/providers.dart';
import '../lib/shared/date_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late SettingsRepository settingsRepo;
  late StatisticsRepository statsRepo;
  late ProviderContainer container;

  final today = getLogicalToday();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    dailyLogRepo = DailyLogRepository(db);
    settingsRepo = SettingsRepository(db);
    statsRepo = StatisticsRepository(db);

    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        projectRepositoryProvider.overrideWithValue(projectRepo),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        dailyLogRepositoryProvider.overrideWithValue(dailyLogRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        statisticsRepositoryProvider.overrideWithValue(statsRepo),
      ],
    );

    // Populate default settings (which defaults to 2 streak shields)
    await settingsRepo.getSettings();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Streak Shields (Time Freeze) Tests', () {
    test('1. Missed day on a project with streak 0 does not consume a shield and breaks streak', () async {
      final projectId = 'p_streak_0';
      final project = ProjectModel(
        id: projectId,
        name: 'No Streak Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 0,
        remainingWords: 1000,
        dailyWordTarget: 200,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)),
        expectedFinishDate: cleanToday.add(const Duration(days: 4)),
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

      // Yesterday's schedule - missed
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final sYesterday = ScheduleModel(
        id: 's_yesterday', projectId: projectId, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([sYesterday]);

      // Run sync rollover
      final syncService = container.read(ongoingSyncServiceProvider);
      await syncService.syncFixedGoalBacklogs([project]);

      // Check setting: shields should still be 2
      final settings = await settingsRepo.getSettings();
      expect(settings.streakShields, 2);

      // Check project: frozenDate is null, streak is 0
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject!.frozenDate, isNull);
      expect(updatedProject.projectStreak, 0);

      // Yesterday's schedule: locked normally, not shielded
      final updatedSchedules = await scheduleRepo.getSchedulesForProject(projectId);
      expect(updatedSchedules.first.locked, isTrue);
      expect(updatedSchedules.first.isShielded, isFalse);
    });

    test('2. Missed day on a project with streak >= 1 consumes 1 shield and freezes yesterday', () async {
      final projectId = 'p_streak_1';
      final project = ProjectModel(
        id: projectId,
        name: 'Streaked Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 200,
        remainingWords: 800,
        dailyWordTarget: 200,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 1, // Active streak!
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      // 2 days ago schedule - completed
      final day2Ago = cleanToday.subtract(const Duration(days: 2));
      final s2Ago = ScheduleModel(
        id: 's_2ago', projectId: projectId, date: day2Ago, plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log2Ago = DailyLogModel(
        id: 'l_2ago', projectId: projectId, scheduleId: 's_2ago', date: day2Ago,
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: day2Ago,
      );

      // Yesterday's schedule - missed
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      final sYesterday = ScheduleModel(
        id: 's_yesterday', projectId: projectId, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([s2Ago, sYesterday]);
      await dailyLogRepo.insertLog(log2Ago);

      final initialSettings = await settingsRepo.getSettings();
      expect(initialSettings.streakShields, 2);

      // Run sync rollover
      final syncService = container.read(ongoingSyncServiceProvider);
      await syncService.syncFixedGoalBacklogs([project]);

      // Check settings: consumed 1 shield (remains 1)
      final settings = await settingsRepo.getSettings();
      expect(settings.streakShields, 1);

      // Check project: frozenDate set to yesterday, streak preserved at 1!
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject!.frozenDate, isNotNull);
      expect(updatedProject.frozenDate!.year, yesterday.year);
      expect(updatedProject.frozenDate!.month, yesterday.month);
      expect(updatedProject.frozenDate!.day, yesterday.day);
      expect(updatedProject.projectStreak, 1);

      // Yesterday's schedule: marked as shielded
      final updatedYesterday = await scheduleRepo.getScheduleForDate(projectId, yesterday);
      expect(updatedYesterday!.isShielded, isTrue);

      // Check logical today is still yesterday!
      final logicalToday = getLogicalTodayForProject(project: updatedProject, schedules: [s2Ago, updatedYesterday]);
      expect(logicalToday.year, yesterday.year);
      expect(logicalToday.month, yesterday.month);
      expect(logicalToday.day, yesterday.day);
    });

    test('3. Logging words within 24 hours completes the frozen day and lifts freeze', () async {
      final projectId = 'p_freeze_solve';
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      
      final project = ProjectModel(
        id: projectId,
        name: 'Freeze Solve Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 200,
        remainingWords: 800,
        dailyWordTarget: 200,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 1,
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        frozenDate: yesterday,
        freezeActivatedAt: DateTime.now(), // Active freeze!
      );
      await projectRepo.insertProject(project);

      final s2Ago = ScheduleModel(
        id: 's_2ago', projectId: projectId, date: cleanToday.subtract(const Duration(days: 2)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log2Ago = DailyLogModel(
        id: 'l_2ago', projectId: projectId, scheduleId: 's_2ago', date: cleanToday.subtract(const Duration(days: 2)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 2)),
      );
      final sYesterday = ScheduleModel(
        id: 's_yesterday', projectId: projectId, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: true,
        isShielded: true,
      );
      await scheduleRepo.insertSchedules([s2Ago, sYesterday]);
      await dailyLogRepo.insertLog(log2Ago);

      // Log 200 words for yesterday
      final loggingService = container.read(loggingServiceProvider);
      await loggingService.logWords(
        projectId: projectId,
        date: yesterday,
        actualWords: 200,
        isAdditive: false,
      );

      // Check project: freeze lifted (frozenDate is null) and streak incremented to 2!
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject!.frozenDate, isNull);
      expect(updatedProject.freezeActivatedAt, isNull);
      expect(updatedProject.projectStreak, 2);

      // Yesterday's schedule: completed is true, isShielded is false
      final updatedYesterday = await scheduleRepo.getScheduleForDate(projectId, yesterday);
      expect(updatedYesterday!.completed, isTrue);
      expect(updatedYesterday.isShielded, isFalse);

      // Logical today is now rolled over to today!
      final logicalToday = getLogicalTodayForProject(project: updatedProject, schedules: [updatedYesterday]);
      expect(logicalToday.year, cleanToday.year);
      expect(logicalToday.month, cleanToday.month);
      expect(logicalToday.day, cleanToday.day);
    });

    test('4. Passing 24 hours without logging words expires freeze and breaks streak', () async {
      final projectId = 'p_freeze_expire';
      final yesterday = cleanToday.subtract(const Duration(days: 1));
      
      final project = ProjectModel(
        id: projectId,
        name: 'Freeze Expire Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 1000,
        writtenWords: 200,
        remainingWords: 800,
        dailyWordTarget: 200,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)),
        expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 1,
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        frozenDate: yesterday,
        freezeActivatedAt: DateTime.now().subtract(const Duration(hours: 25)), // Expired!
      );
      await projectRepo.insertProject(project);

      final s2Ago = ScheduleModel(
        id: 's_2ago', projectId: projectId, date: cleanToday.subtract(const Duration(days: 2)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log2Ago = DailyLogModel(
        id: 'l_2ago', projectId: projectId, scheduleId: 's_2ago', date: cleanToday.subtract(const Duration(days: 2)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 2)),
      );
      final sYesterday = ScheduleModel(
        id: 's_yesterday', projectId: projectId, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: true,
        isShielded: true,
      );
      await scheduleRepo.insertSchedules([s2Ago, sYesterday]);
      await dailyLogRepo.insertLog(log2Ago);

      // Run sync rollover
      final syncService = container.read(ongoingSyncServiceProvider);
      await syncService.syncFixedGoalBacklogs([project]);

      // Check project: freeze cleared, streak reset to 0
      final updatedProject = await projectRepo.getProjectById(projectId);
      expect(updatedProject!.frozenDate, isNull);
      expect(updatedProject.projectStreak, 0);

      // Yesterday's schedule: locked, backlog created in logs
      final logs = await dailyLogRepo.getLogsForProject(projectId);
      final logYesterday = logs.firstWhere((l) => l.date.year == yesterday.year && l.date.month == yesterday.month && l.date.day == yesterday.day);
      expect(logYesterday.backlogCreated, 200);
    });

    test('5. Multiple projects missing same day consumes only 1 global shield', () async {
      final settings = await settingsRepo.getSettings();
      expect(settings.streakShields, 2);

      final p1Id = 'p_multi_1';
      final p2Id = 'p_multi_2';
      final yesterday = cleanToday.subtract(const Duration(days: 1));

      final p1 = ProjectModel(
        id: p1Id, name: 'Book 1', status: ProjectStatus.active, targetWords: 1000,
        writtenWords: 200, remainingWords: 800, dailyWordTarget: 200, backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 2)), expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.fixed, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 1, longestProjectStreak: 1, currentWeek: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final p2 = ProjectModel(
        id: p2Id, name: 'Book 2', status: ProjectStatus.active, targetWords: 1000,
        writtenWords: 600, remainingWords: 400, dailyWordTarget: 200, backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 4)), expectedFinishDate: cleanToday.add(const Duration(days: 3)),
        restMode: RestMode.fixed, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 3, longestProjectStreak: 3, currentWeek: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(p1);
      await projectRepo.insertProject(p2);

      final s2Ago1 = ScheduleModel(
        id: 's_2ago1', projectId: p1Id, date: cleanToday.subtract(const Duration(days: 2)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log2Ago1 = DailyLogModel(
        id: 'l_2ago1', projectId: p1Id, scheduleId: 's_2ago1', date: cleanToday.subtract(const Duration(days: 2)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 2)),
      );
      
      final s2Ago2 = ScheduleModel(
        id: 's_2ago2', projectId: p2Id, date: cleanToday.subtract(const Duration(days: 2)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log2Ago2 = DailyLogModel(
        id: 'l_2ago2', projectId: p2Id, scheduleId: 's_2ago2', date: cleanToday.subtract(const Duration(days: 2)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 2)),
      );

      final s3Ago2 = ScheduleModel(
        id: 's_3ago2', projectId: p2Id, date: cleanToday.subtract(const Duration(days: 3)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log3Ago2 = DailyLogModel(
        id: 'l_3ago2', projectId: p2Id, scheduleId: 's_3ago2', date: cleanToday.subtract(const Duration(days: 3)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 3)),
      );

      final s4Ago2 = ScheduleModel(
        id: 's_4ago2', projectId: p2Id, date: cleanToday.subtract(const Duration(days: 4)), plannedWords: 200,
        isRestDay: false, completed: true, automaticRestDay: false, locked: true,
      );
      final log4Ago2 = DailyLogModel(
        id: 'l_4ago2', projectId: p2Id, scheduleId: 's_4ago2', date: cleanToday.subtract(const Duration(days: 4)),
        plannedWords: 200, actualWords: 200, carryForwardWords: 0, backlogCreated: 0,
        completed: true, loggedAt: cleanToday.subtract(const Duration(days: 4)),
      );

      final sYesterday1 = ScheduleModel(
        id: 's_y1', projectId: p1Id, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      final sYesterday2 = ScheduleModel(
        id: 's_y2', projectId: p2Id, date: yesterday, plannedWords: 200,
        isRestDay: false, completed: false, automaticRestDay: false, locked: false,
      );
      await scheduleRepo.insertSchedules([s2Ago1, s2Ago2, s3Ago2, s4Ago2, sYesterday1, sYesterday2]);
      await dailyLogRepo.insertLog(log2Ago1);
      await dailyLogRepo.insertLog(log2Ago2);
      await dailyLogRepo.insertLog(log3Ago2);
      await dailyLogRepo.insertLog(log4Ago2);

      // Run sync rollover
      final syncService = container.read(ongoingSyncServiceProvider);
      await syncService.syncFixedGoalBacklogs([p1, p2]);

      // Verify that exactly 1 shield was consumed (remains 1)
      final updatedSettings = await settingsRepo.getSettings();
      expect(updatedSettings.streakShields, 1);

      // Verify both books were frozen on yesterday
      final updatedP1 = await projectRepo.getProjectById(p1Id);
      final updatedP2 = await projectRepo.getProjectById(p2Id);
      expect(updatedP1!.frozenDate, isNotNull);
      expect(updatedP2!.frozenDate, isNotNull);
      expect(updatedP1.projectStreak, 1);
      expect(updatedP2.projectStreak, 3);
    });
  });
}
