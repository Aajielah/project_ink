import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../lib/models/project.dart';
import '../lib/models/schedule.dart';
import '../lib/models/daily_log.dart';
import '../lib/models/statistics.dart';
import '../lib/services/logging_service.dart';
import '../lib/repositories/project_repository.dart';
import '../lib/repositories/schedule_repository.dart';
import '../lib/repositories/daily_log_repository.dart';
import '../lib/repositories/statistics_repository.dart';

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
  Future<void> recalculateStatistics() async {
    // Fake recalculate: just set arbitrary values or leave unchanged for testing
  }
}

void main() {
  late FakeProjectRepository projectRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeDailyLogRepository logRepo;
  late FakeStatisticsRepository statsRepo;
  late LoggingService service;

  final today = DateTime.now();
  final cleanToday = DateTime(today.year, today.month, today.day);

  setUp(() {
    projectRepo = FakeProjectRepository();
    scheduleRepo = FakeScheduleRepository();
    logRepo = FakeDailyLogRepository();
    statsRepo = FakeStatisticsRepository();
    service = LoggingService(
      projectRepo,
      scheduleRepo,
      logRepo,
      statsRepo,
    );
  });

  group('Logging Safety & Carry-Forward Capping Tests', () {
    test('Logging excess words only carries forward up to one day target', () async {
      // 1. Create a project with target = 3000 words per day
      final project = ProjectModel(
        id: 'proj1',
        name: 'Safe Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 30000,
        writtenWords: 0,
        remainingWords: 30000,
        dailyWordTarget: 3000,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 9)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: cleanToday,
        updatedAt: cleanToday,
        pendingCarryForward: 0,
      );
      projectRepo.db[project.id] = project;

      // 2. Insert today's schedule row with planned = 3000
      final todaySchedule = ScheduleModel(
        id: 'sched_today',
        projectId: project.id,
        date: cleanToday,
        plannedWords: 3000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      scheduleRepo.db.add(todaySchedule);

      // 3. Log 9000 words (6000 excess words). Carry forward cap should limit credit to 3000.
      final isCompleted = await service.logWords(
        projectId: project.id,
        date: cleanToday,
        actualWords: 9000,
      );

      expect(isCompleted, isTrue);

      final updatedProject = projectRepo.db[project.id]!;
      // Total written: 9000
      expect(updatedProject.writtenWords, 9000);
      // Excess is 6000, but capped at project.dailyWordTarget (3000)
      expect(updatedProject.pendingCarryForward, 3000);
    });

    test('Pending carry-forward credit is auto-applied on a new day startup', () async {
      // 1. Create a project with pending carry-forward of 3000 words
      final project = ProjectModel(
        id: 'proj1',
        name: 'Auto Carry Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 30000,
        writtenWords: 9000,
        remainingWords: 21000,
        dailyWordTarget: 3000,
        backlogWords: 0,
        startDate: cleanToday.subtract(const Duration(days: 1)),
        expectedFinishDate: cleanToday.add(const Duration(days: 8)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 1,
        longestProjectStreak: 1,
        currentWeek: 1,
        createdAt: cleanToday.subtract(const Duration(days: 1)),
        updatedAt: cleanToday,
        pendingCarryForward: 3000, // <-- 3000 words credit waiting
      );
      projectRepo.db[project.id] = project;

      // 2. Today's schedule row
      final todaySchedule = ScheduleModel(
        id: 'sched_today',
        projectId: project.id,
        date: cleanToday,
        plannedWords: 3000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      scheduleRepo.db.add(todaySchedule);

      // 3. Trigger catch-up check
      await service.checkAndApplyPendingCarryForward([project]);

      final updatedProject = projectRepo.db[project.id]!;
      // Credit should be cleared
      expect(updatedProject.pendingCarryForward, 0);
      // Today's schedule should be marked completed
      final sched = await scheduleRepo.getScheduleForDate(project.id, cleanToday);
      expect(sched!.completed, isTrue);
      // Daily log should be recorded with the 3000 words
      final log = await logRepo.getLogForDate(project.id, cleanToday);
      expect(log!.actualWords, 3000);
    });

    test('Editing today\'s log correctly recalculates progress and pending credit', () async {
      // 1. Create project
      final project = ProjectModel(
        id: 'proj1',
        name: 'Editable Book',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 30000,
        writtenWords: 0,
        remainingWords: 30000,
        dailyWordTarget: 3000,
        backlogWords: 0,
        startDate: cleanToday,
        expectedFinishDate: cleanToday.add(const Duration(days: 9)),
        restMode: RestMode.fixed,
        allowedRestDays: 0,
        remainingRestDays: 0,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: cleanToday,
        updatedAt: cleanToday,
        pendingCarryForward: 0,
      );
      projectRepo.db[project.id] = project;

      // 2. Today's schedule row
      final todaySchedule = ScheduleModel(
        id: 'sched_today',
        projectId: project.id,
        date: cleanToday,
        plannedWords: 3000,
        isRestDay: false,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      scheduleRepo.db.add(todaySchedule);

      // Log 9000 words initially
      await service.logWords(
        projectId: project.id,
        date: cleanToday,
        actualWords: 9000,
      );

      var updated = projectRepo.db[project.id]!;
      expect(updated.pendingCarryForward, 3000);
      expect(updated.writtenWords, 9000);

      // Edit today's log to 4000 words
      await service.logWords(
        projectId: project.id,
        date: cleanToday,
        actualWords: 4000,
        isAdditive: false,
      );

      updated = projectRepo.db[project.id]!;
      // Capped carry-forward: excess is 1000, so pendingCarryForward should become 1000
      expect(updated.pendingCarryForward, 1000);
      expect(updated.writtenWords, 4000);
    });
  });
}
