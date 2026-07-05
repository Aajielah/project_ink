import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import '../lib/database/database.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLogRepository dailyLogRepo;
  late StatisticsRepository statsRepo;

  setUp(() {
    // Setup in-memory SQLite database
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepository(db);
    scheduleRepo = ScheduleRepository(db);
    dailyLogRepo = DailyLogRepository(db);
    statsRepo = StatisticsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Statistics Repository - Dynamic On-Demand Calculations', () {
    test('Calculates statistics correctly and excludes ongoing projects from backlog', () async {
      final uuid = const Uuid();

      // 1. Create a Fixed Goal project with backlog
      final fixedProjId = uuid.v4();
      final fixedProj = ProjectModel(
        id: fixedProjId,
        name: 'Fixed Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 1000,
        remainingWords: 9000,
        dailyWordTarget: 500,
        backlogWords: 1200, // should be counted
        startDate: DateTime(2026, 7, 1),
        expectedFinishDate: DateTime(2026, 7, 20),
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(fixedProj);

      // 2. Create an Ongoing project with backlog (which should be ignored in stats.currentBacklog)
      final ongoingProjId = uuid.v4();
      final ongoingProj = ProjectModel(
        id: ongoingProjId,
        name: 'Ongoing Book',
        status: ProjectStatus.active,
        projectType: ProjectType.ongoing,
        targetWords: 0,
        writtenWords: 500,
        remainingWords: 0,
        dailyWordTarget: 300,
        backlogWords: 500, // should NOT be counted in currentBacklog
        startDate: DateTime(2026, 7, 1),
        expectedFinishDate: DateTime(2026, 7, 1),
        restMode: RestMode.flexible,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(ongoingProj);

      // 3. Create logs on different days
      final date1 = DateTime(2026, 7, 1);
      final date2 = DateTime(2026, 7, 2);

      // Insert schedules first to satisfy foreign key constraints in DB
      await scheduleRepo.insertSchedules([
        ScheduleModel(id: 's1', projectId: fixedProjId, date: date1, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's2', projectId: fixedProjId, date: date2, plannedWords: 500, isRestDay: false, completed: false, automaticRestDay: false, locked: false),
        ScheduleModel(id: 's3', projectId: ongoingProjId, date: date1, plannedWords: 300, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
      ]);

      // Log 1: Date 1 (600 words)
      await dailyLogRepo.insertLog(DailyLogModel(
        id: uuid.v4(), projectId: fixedProjId, scheduleId: 's1',
        date: date1, plannedWords: 500, actualWords: 600,
        carryForwardWords: 100, backlogCreated: 0, completed: true, loggedAt: DateTime.now(),
      ));

      // Log 2: Date 2 (300 words)
      await dailyLogRepo.insertLog(DailyLogModel(
        id: uuid.v4(), projectId: fixedProjId, scheduleId: 's2',
        date: date2, plannedWords: 500, actualWords: 300,
        carryForwardWords: 0, backlogCreated: 1200, completed: false, loggedAt: DateTime.now(),
      ));

      // Log 3: Date 1 for ongoing (400 words) - same day as Log 1
      await dailyLogRepo.insertLog(DailyLogModel(
        id: uuid.v4(), projectId: ongoingProjId, scheduleId: 's3',
        date: date1, plannedWords: 300, actualWords: 400,
        carryForwardWords: 100, backlogCreated: 0, completed: true, loggedAt: DateTime.now(),
      ));

      // 4. Calculate dynamic statistics
      final stats = await statsRepo.getStatistics();

      // Assertions:
      // Lifetime Words: 600 + 300 + 400 = 1300
      expect(stats.lifetimeWords, 1300);

      // Writing Days: 2 distinct dates (Date 1 and Date 2)
      expect(stats.writingDays, 2);

      // Average words: 1300 / 2 = 650.0
      expect(stats.averageWordsPerDay, 650.0);

      // Backlog: only active fixed projects should contribute (1200), ignoring ongoing (500)
      expect(stats.currentBacklog, 1200);
    });

    test('Calculates streaks correctly including rest days preserving global streaks', () async {
      final uuid = const Uuid();
      final projId = uuid.v4();

      final today = DateTime.now();
      final cleanToday = DateTime(today.year, today.month, today.day);

      final day1 = cleanToday.subtract(const Duration(days: 3));
      final day2 = cleanToday.subtract(const Duration(days: 2));
      final day3 = cleanToday.subtract(const Duration(days: 1)); // rest day
      final day4 = cleanToday; // today, completed

      final project = ProjectModel(
        id: projId, name: 'Book', status: ProjectStatus.active, projectType: ProjectType.fixed,
        targetWords: 10000, writtenWords: 0, remainingWords: 10000, dailyWordTarget: 500, backlogWords: 0,
        startDate: day1, expectedFinishDate: day4,
        restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 0, longestProjectStreak: 0, currentWeek: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(project);

      await scheduleRepo.insertSchedules([
        ScheduleModel(id: 's1', projectId: projId, date: day1, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's2', projectId: projId, date: day2, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's3', projectId: projId, date: day3, plannedWords: 0, isRestDay: true, completed: false, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's4', projectId: projId, date: day4, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
      ]);

      // Add completed logs for Day 1, Day 2, and Day 4
      await dailyLogRepo.insertLog(DailyLogModel(id: uuid.v4(), projectId: projId, scheduleId: 's1', date: day1, plannedWords: 500, actualWords: 500, carryForwardWords: 0, backlogCreated: 0, completed: true, loggedAt: day1));
      await dailyLogRepo.insertLog(DailyLogModel(id: uuid.v4(), projectId: projId, scheduleId: 's2', date: day2, plannedWords: 500, actualWords: 500, carryForwardWords: 0, backlogCreated: 0, completed: true, loggedAt: day2));
      await dailyLogRepo.insertLog(DailyLogModel(id: uuid.v4(), projectId: projId, scheduleId: 's4', date: day4, plannedWords: 500, actualWords: 500, carryForwardWords: 0, backlogCreated: 0, completed: true, loggedAt: day4));

      // Calculate dynamic statistics
      final stats = await statsRepo.getStatistics();

      // Assertions:
      // Day 1: Completed (streak=1)
      // Day 2: Completed (streak=2)
      // Day 3: Rest Day (streak=2) - preserves!
      // Day 4: Completed (streak=3)
      // Total Global Streak = 3
      expect(stats.currentGlobalStreak, 3);
      expect(stats.longestGlobalStreak, 3);
    });
  });

  group('Cascade Deletion Transaction Tests', () {
    test('Deleting a project deletes its schedules and logs, then recalculates statistics in a single transaction', () async {
      final uuid = const Uuid();
      final p1Id = uuid.v4();
      final p2Id = uuid.v4();

      // Insert Project 1 and 2
      final p1 = ProjectModel(
        id: p1Id, name: 'Project 1', status: ProjectStatus.active, projectType: ProjectType.fixed,
        targetWords: 5000, writtenWords: 0, remainingWords: 5000, dailyWordTarget: 500, backlogWords: 0,
        startDate: DateTime(2026, 7, 1), expectedFinishDate: DateTime(2026, 7, 5),
        restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 0, longestProjectStreak: 0, currentWeek: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final p2 = ProjectModel(
        id: p2Id, name: 'Project 2', status: ProjectStatus.active, projectType: ProjectType.fixed,
        targetWords: 5000, writtenWords: 0, remainingWords: 5000, dailyWordTarget: 500, backlogWords: 0,
        startDate: DateTime(2026, 7, 1), expectedFinishDate: DateTime(2026, 7, 5),
        restMode: RestMode.flexible, allowedRestDays: 0, remainingRestDays: 0,
        projectStreak: 0, longestProjectStreak: 0, currentWeek: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await projectRepo.insertProject(p1);
      await projectRepo.insertProject(p2);

      // Insert schedules and logs for both
      final date = DateTime(2026, 7, 1);
      await scheduleRepo.insertSchedules([
        ScheduleModel(id: 's_p1', projectId: p1Id, date: date, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
        ScheduleModel(id: 's_p2', projectId: p2Id, date: date, plannedWords: 500, isRestDay: false, completed: true, automaticRestDay: false, locked: true),
      ]);

      await dailyLogRepo.insertLog(DailyLogModel(id: 'l_p1', projectId: p1Id, scheduleId: 's_p1', date: date, plannedWords: 500, actualWords: 600, carryForwardWords: 100, backlogCreated: 0, completed: true, loggedAt: date));
      await dailyLogRepo.insertLog(DailyLogModel(id: 'l_p2', projectId: p2Id, scheduleId: 's_p2', date: date, plannedWords: 500, actualWords: 700, carryForwardWords: 200, backlogCreated: 0, completed: true, loggedAt: date));

      // Initial stats check
      var stats = await statsRepo.getStatistics();
      expect(stats.lifetimeWords, 1300); // 600 + 700

      // Perform atomic cascade delete for Project 1
      await db.transaction(() async {
        await projectRepo.deleteProject(p1Id);
        await scheduleRepo.deleteSchedulesForProject(p1Id);
        await dailyLogRepo.deleteLogsForProject(p1Id);
      });

      // Verify Project 1 data is completely removed from DB
      final deletedProject = await projectRepo.getProjectById(p1Id);
      expect(deletedProject, isNull);

      final p1Schedules = await scheduleRepo.getSchedulesForProject(p1Id);
      expect(p1Schedules.isEmpty, isTrue);

      final p1Log = await dailyLogRepo.getLogForDate(p1Id, date);
      expect(p1Log, isNull);

      // Recalculate and assert updated stats
      stats = await statsRepo.getStatistics();
      // Lifetime Words should drop to only Project 2's words (700)
      expect(stats.lifetimeWords, 700);
    });
  });
}
