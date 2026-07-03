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
}
