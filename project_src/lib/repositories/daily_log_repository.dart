import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/daily_log.dart';

class DailyLogRepository {
  final AppDatabase _db;

  DailyLogRepository(this._db);

  DailyLogModel _mapToModel(DailyLog data) {
    return DailyLogModel(
      id: data.id,
      projectId: data.projectId,
      scheduleId: data.scheduleId,
      date: data.date,
      plannedWords: data.plannedWords,
      actualWords: data.actualWords,
      carryForwardWords: data.carryForwardWords,
      backlogCreated: data.backlogCreated,
      completed: data.completed,
      loggedAt: data.loggedAt,
    );
  }

  DailyLogsCompanion _mapToCompanion(DailyLogModel model) {
    return DailyLogsCompanion(
      id: Value(model.id),
      projectId: Value(model.projectId),
      scheduleId: Value(model.scheduleId),
      date: Value(model.date),
      plannedWords: Value(model.plannedWords),
      actualWords: Value(model.actualWords),
      carryForwardWords: Value(model.carryForwardWords),
      backlogCreated: Value(model.backlogCreated),
      completed: Value(model.completed),
      loggedAt: Value(model.loggedAt),
    );
  }

  Future<List<DailyLogModel>> getLogsForProject(String projectId) async {
    final query = _db.select(_db.dailyLogs)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<DailyLogModel?> getLogForDate(String projectId, DateTime date) async {
    final query = _db.select(_db.dailyLogs)
      ..where((t) => t.projectId.equals(projectId) & t.date.equals(date));
    final data = await query.getSingleOrNull();
    return data != null ? _mapToModel(data) : null;
  }

  Future<void> insertLog(DailyLogModel log) async {
    await _db.into(_db.dailyLogs).insert(_mapToCompanion(log), mode: InsertMode.insertOrReplace);
  }

  Future<void> deleteLogsForProject(String projectId) async {
    await (_db.delete(_db.dailyLogs)..where((t) => t.projectId.equals(projectId))).go();
  }
}
