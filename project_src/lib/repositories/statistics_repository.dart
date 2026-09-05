import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/statistics.dart';
import '../shared/date_utils.dart';

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
    // 1. Fetch all projects
    final projects = await _db.select(_db.projects).get();

    // 2. Count completed projects
    final projectsCompletedCount = projects.where((p) => p.status == 'completed').length;

    // 4. Fetch all logs
    final logs = await _db.select(_db.dailyLogs).get();

    // 3. Calculate currentBacklog (excluding ongoing projects!)
    int currentBacklogVal = 0;
    for (final p in projects) {
      if (p.projectType == 'fixed') {
        final projectLogs = logs.where((l) => l.projectId == p.id).toList();
        final calculatedBacklog = projectLogs.fold<int>(0, (sum, l) => sum + (l.backlogCreated > 0 ? l.backlogCreated : 0));
        
        if (p.backlogWords != calculatedBacklog) {
          final companion = ProjectsCompanion(
            backlogWords: Value(calculatedBacklog),
          );
          await (_db.update(_db.projects)..where((t) => t.id.equals(p.id))).write(companion);
        }
        
        if (p.status == 'active') {
          currentBacklogVal += calculatedBacklog;
        }
      }
    }

    // 5. Calculate lifetimeWords
    int lifetimeWordsVal = 0;
    for (final l in logs) {
      lifetimeWordsVal += l.actualWords;
    }

    // 6. Calculate writingDays (Count of distinct calendar dates with actualWords > 0)
    final Set<String> distinctWritingDays = {};
    for (final l in logs) {
      if (l.actualWords > 0) {
        final dateKey = '${l.date.year}-${l.date.month}-${l.date.day}';
        distinctWritingDays.add(dateKey);
      }
    }
    final int writingDaysVal = distinctWritingDays.length;

    // 7. Calculate averageWordsPerDay (Lifetime Words ÷ Total Writing Days)
    final double avgWords = writingDaysVal > 0 ? lifetimeWordsVal / writingDaysVal : 0.0;

    // 8. Calculate restDaysUsed (Unique calendar dates where ALL active schedules on that date are rest days)
    final schedules = await _db.select(_db.schedules).get();
    int restDaysUsedVal = 0;
    
    final Map<String, List<Schedule>> schedulesByDateAll = {};
    for (final s in schedules) {
      final dateKey = '${s.date.year}-${s.date.month}-${s.date.day}';
      schedulesByDateAll.putIfAbsent(dateKey, () => []).add(s);
    }
    
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);
    
    for (final entry in schedulesByDateAll.entries) {
      final dateParts = entry.key.split('-');
      final cleanSchedDate = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      
      if (cleanSchedDate.isBefore(cleanToday) || cleanSchedDate.isAtSameMomentAs(cleanToday)) {
        final daySchedules = entry.value;
        if (daySchedules.isNotEmpty && daySchedules.every((s) => s.isRestDay || s.automaticRestDay)) {
          if (cleanSchedDate.isAtSameMomentAs(cleanToday)) {
            if (daySchedules.every((s) => s.locked)) {
              restDaysUsedVal++;
            }
          } else {
            restDaysUsedVal++;
          }
        }
      }
    }

    // 9. Calculate streaks (Global Streak)
    int currentStreak = 0;
    int longestStreak = 0;
    if (schedules.isNotEmpty) {
      DateTime minDate = schedules.first.date;
      for (final s in schedules) {
        if (s.date.isBefore(minDate)) minDate = s.date;
      }
      
      final cleanMin = DateTime(minDate.year, minDate.month, minDate.day);

      final Map<String, List<Schedule>> schedulesByDate = {};
      for (final s in schedules) {
        final dateKey = '${s.date.year}-${s.date.month}-${s.date.day}';
        schedulesByDate.putIfAbsent(dateKey, () => []).add(s);
      }

      final List<String> dailyStates = [];
      var tempDate = cleanMin;
      
      while (tempDate.isBefore(cleanToday) || tempDate.isAtSameMomentAs(cleanToday)) {
        final dateKey = '${tempDate.year}-${tempDate.month}-${tempDate.day}';
        final dayScheds = schedulesByDate[dateKey] ?? [];
        
        if (dayScheds.isEmpty) {
          if (tempDate.isBefore(cleanToday)) {
            // Check if any writing occurred on this unscheduled day
            final hasWriting = logs.any((l) =>
                l.actualWords > 0 &&
                l.date.year == tempDate.year &&
                l.date.month == tempDate.month &&
                l.date.day == tempDate.day);
            if (hasWriting) {
              dailyStates.add('completed');
            } else {
              // Past unscheduled day with zero writing breaks the active streak
              dailyStates.add('failed');
            }
          } else {
            // Today with no schedules is neutral
            dailyStates.add('rest');
          }
        } else {
          final isToday = tempDate.isAtSameMomentAs(cleanToday);
          bool hasUncompletedWriting = false;
          int totalWritingSchedules = 0;
          int completedWritingSchedules = 0;

          for (final s in dayScheds) {
            final isRestOrRecoveryOrShield = s.isRestDay || s.automaticRestDay || s.isRecoveryDay || s.isShielded;
            if (!isRestOrRecoveryOrShield) {
              totalWritingSchedules++;
              if (s.completed) {
                completedWritingSchedules++;
              } else {
                if (isToday && !s.locked) {
                  // user still has time to complete
                } else {
                  hasUncompletedWriting = true;
                }
              }
            }
          }

          if (hasUncompletedWriting) {
            dailyStates.add('failed');
          } else if (totalWritingSchedules > 0 && completedWritingSchedules == totalWritingSchedules) {
            dailyStates.add('completed');
          } else {
            dailyStates.add('rest');
          }
        }
        
        tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
      }

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
    }

    final stats = StatisticsModel(
      id: 'computed_stats',
      lifetimeWords: lifetimeWordsVal,
      averageWordsPerDay: avgWords,
      currentGlobalStreak: currentStreak,
      longestGlobalStreak: longestStreak,
      projectsCompleted: projectsCompletedCount,
      writingDays: writingDaysVal,
      restDaysUsed: restDaysUsedVal,
      currentBacklog: currentBacklogVal,
    );

    // Persist stats in sqlite table for direct inspection/backups
    await insertStatistics(stats);

    return stats;
  }

  Future<void> insertStatistics(StatisticsModel stats) async {
    await _db.into(_db.statisticsTable).insert(_mapToCompanion(stats), mode: InsertMode.insertOrReplace);
  }

  Future<void> updateStatistics(StatisticsModel stats) async {
    await (_db.update(_db.statisticsTable)..where((t) => t.id.equals(stats.id)))
        .write(_mapToCompanion(stats));
  }

  Future<void> recalculateStatistics() async {
    await getStatistics();
  }
}
