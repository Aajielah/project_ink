import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/statistics.dart';

class StatisticsRepository {
  final AppDatabase _db;

  StatisticsRepository(this._db);

  StatisticsModel _mapToModel(StatisticsTableData data) {
    return StatisticsModel(
      id: data.id,
      lifetimeWords: data.lifetimeWords,
      averageWordsPerDay: data.averageWordsPerDay,
      currentGlobalStreak: data.currentGlobalStreak,
      longestGlobalStreak: data.longestGlobalStreak,
      projectsCompleted: data.projectsCompleted,
      writingDays: data.writingDays,
      restDaysUsed: data.restDaysUsed,
      currentBacklog: data.currentBacklog,
    );
  }

  StatisticsTableCompanion _mapToCompanion(StatisticsModel model) {
    return StatisticsTableCompanion(
      id: Value(model.id),
      lifetimeWords: Value(model.lifetimeWords),
      averageWordsPerDay: Value(model.averageWordsPerDay),
      currentGlobalStreak: Value(model.currentGlobalStreak),
      longestGlobalStreak: Value(model.longestGlobalStreak),
      projectsCompleted: Value(model.projectsCompleted),
      writingDays: Value(model.writingDays),
      restDaysUsed: Value(model.restDaysUsed),
      currentBacklog: Value(model.currentBacklog),
    );
  }

  Future<StatisticsModel> getStatistics() async {
    final results = await _db.select(_db.statisticsTable).get();
    if (results.isEmpty) {
      // Create default empty statistics row
      final defaultStats = StatisticsModel(
        id: const Uuid().v4(),
        lifetimeWords: 0,
        averageWordsPerDay: 0.0,
        currentGlobalStreak: 0,
        longestGlobalStreak: 0,
        projectsCompleted: 0,
        writingDays: 0,
        restDaysUsed: 0,
        currentBacklog: 0,
      );
      await insertStatistics(defaultStats);
      return defaultStats;
    }
    return _mapToModel(results.first);
  }

  Future<void> insertStatistics(StatisticsModel stats) async {
    await _db.into(_db.statisticsTable).insert(_mapToCompanion(stats), mode: InsertMode.insertOrReplace);
  }

  Future<void> updateStatistics(StatisticsModel stats) async {
    await (_db.update(_db.statisticsTable)..where((t) => t.id.equals(stats.id)))
        .write(_mapToCompanion(stats));
  }

  Future<void> recalculateStatistics() async {
    // 1. Get stats row (or create if empty)
    final stats = await getStatistics();

    // 2. Fetch all projects
    final projects = await _db.select(_db.projects).get();

    // 3. Count completed projects
    final projectsCompletedCount = projects.where((p) => p.status == 'completed').length;

    // 4. Calculate currentBacklog
    int currentBacklogVal = 0;
    for (final p in projects) {
      if (p.status == 'active' && p.projectType == 'fixed') {
        currentBacklogVal += p.backlogWords;
      }
    }

    // 5. Fetch all logs
    final logs = await _db.select(_db.dailyLogs).get();

    // 6. Calculate lifetimeWords
    int lifetimeWordsVal = 0;
    for (final l in logs) {
      lifetimeWordsVal += l.actualWords;
    }

    // 7. Calculate writingDays (Count of distinct calendar dates with actualWords > 0)
    final Set<String> distinctWritingDays = {};
    for (final l in logs) {
      if (l.actualWords > 0) {
        final dateKey = '${l.date.year}-${l.date.month}-${l.date.day}';
        distinctWritingDays.add(dateKey);
      }
    }
    final int writingDaysVal = distinctWritingDays.length;

    // 8. Calculate averageWordsPerDay (Lifetime Words ÷ Total Writing Days)
    final double avgWords = writingDaysVal > 0 ? lifetimeWordsVal / writingDaysVal : 0.0;

    // 9. Calculate restDaysUsed
    final schedules = await _db.select(_db.schedules).get();
    int restDaysUsedVal = 0;
    for (final s in schedules) {
      if (s.isRestDay || s.automaticRestDay) {
        final today = DateTime.now();
        final cleanToday = DateTime(today.year, today.month, today.day);
        final cleanSchedDate = DateTime(s.date.year, s.date.month, s.date.day);
        if (cleanSchedDate.isBefore(cleanToday) || (cleanSchedDate.isAtSameMomentAs(cleanToday) && s.locked)) {
          restDaysUsedVal++;
        }
      }
    }

    // 10. Calculate streaks (Global Streak)
    if (schedules.isEmpty) {
      await updateStatistics(stats.copyWith(
        lifetimeWords: 0,
        averageWordsPerDay: 0.0,
        currentGlobalStreak: 0,
        longestGlobalStreak: 0,
        projectsCompleted: 0,
        writingDays: 0,
        restDaysUsed: 0,
        currentBacklog: 0,
      ));
      return;
    }

    DateTime minDate = schedules.first.date;
    DateTime maxDate = schedules.first.date;
    for (final s in schedules) {
      if (s.date.isBefore(minDate)) minDate = s.date;
      if (s.date.isAfter(maxDate)) maxDate = s.date;
    }
    
    final cleanMin = DateTime(minDate.year, minDate.month, minDate.day);
    final cleanMax = DateTime(maxDate.year, maxDate.month, maxDate.day);

    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    final Map<String, List<Schedule>> schedulesByDate = {};
    for (final s in schedules) {
      final dateKey = '${s.date.year}-${s.date.month}-${s.date.day}';
      schedulesByDate.putIfAbsent(dateKey, () => []).add(s);
    }
    
    final Map<String, List<DailyLog>> logsByDate = {};
    for (final l in logs) {
      final dateKey = '${l.date.year}-${l.date.month}-${l.date.day}';
      logsByDate.putIfAbsent(dateKey, () => []).add(l);
    }

    final List<String> dailyStates = [];
    var tempDate = cleanMin;
    
    while (tempDate.isBefore(cleanToday) || tempDate.isAtSameMomentAs(cleanToday)) {
      final dateKey = '${tempDate.year}-${tempDate.month}-${tempDate.day}';
      final dayScheds = schedulesByDate[dateKey] ?? [];
      final dayLogs = logsByDate[dateKey] ?? [];
      
      if (dayScheds.isEmpty && dayLogs.isEmpty) {
        dailyStates.add('rest');
      } else {
        bool hasCompleted = dayLogs.any((l) => l.completed);
        bool hasScheduledWriting = dayScheds.any((s) => !s.isRestDay);
        
        if (hasCompleted) {
          dailyStates.add('completed');
        } else if (hasScheduledWriting) {
          dailyStates.add('failed');
        } else {
          dailyStates.add('rest');
        }
      }
      
      tempDate = tempDate.add(const Duration(days: 1));
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (final state in dailyStates) {
      if (state == 'completed') {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (state == 'failed') {
        tempStreak = 0;
      }
    }
    currentStreak = tempStreak;

    final updatedStats = stats.copyWith(
      lifetimeWords: lifetimeWordsVal,
      averageWordsPerDay: avgWords,
      currentGlobalStreak: currentStreak,
      longestGlobalStreak: longestStreak,
      projectsCompleted: projectsCompletedCount,
      writingDays: writingDaysVal,
      restDaysUsed: restDaysUsedVal,
      currentBacklog: currentBacklogVal,
    );

    await updateStatistics(updatedStats);
  }
}
