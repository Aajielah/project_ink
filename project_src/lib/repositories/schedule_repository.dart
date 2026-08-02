import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final AppDatabase _db;

  ScheduleRepository(this._db);

  ScheduleModel _mapToModel(Schedule data) {
    return ScheduleModel(
      id: data.id,
      projectId: data.projectId,
      date: data.date,
      plannedWords: data.plannedWords,
      isRestDay: data.isRestDay,
      completed: data.completed,
      automaticRestDay: data.automaticRestDay,
      locked: data.locked,
      isRecoveryDay: data.isRecoveryDay,
    );
  }

  SchedulesCompanion _mapToCompanion(ScheduleModel model) {
    return SchedulesCompanion(
      id: Value(model.id),
      projectId: Value(model.projectId),
      date: Value(model.date),
      plannedWords: Value(model.plannedWords),
      isRestDay: Value(model.isRestDay),
      completed: Value(model.completed),
      automaticRestDay: Value(model.automaticRestDay),
      locked: Value(model.locked),
      isRecoveryDay: Value(model.isRecoveryDay),
    );
  }

  Future<List<ScheduleModel>> getSchedulesForProject(String projectId) async {
    final query = _db.select(_db.schedules)
      ..where((t) => t.projectId.equals(projectId))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<List<ScheduleModel>> getSchedulesForDateRange(
      String projectId, DateTime start, DateTime end) async {
    final query = _db.select(_db.schedules)
      ..where((t) => t.projectId.equals(projectId) & t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<ScheduleModel?> getScheduleForDate(String projectId, DateTime date) async {
    final query = _db.select(_db.schedules)
      ..where((t) => t.projectId.equals(projectId) & t.date.equals(date));
    final data = await query.getSingleOrNull();
    return data != null ? _mapToModel(data) : null;
  }

  Future<void> insertSchedules(List<ScheduleModel> schedules) async {
    await _db.batch((batch) {
      batch.insertAll(
        _db.schedules,
        schedules.map(_mapToCompanion).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await (_db.update(_db.schedules)..where((t) => t.id.equals(schedule.id)))
        .write(_mapToCompanion(schedule));
  }

  Future<void> deleteSchedulesForProject(String projectId) async {
    await (_db.delete(_db.schedules)..where((t) => t.projectId.equals(projectId))).go();
  }

  Future<void> deleteUnlockedFutureSchedules(String projectId, DateTime fromDate) async {
    await (_db.delete(_db.schedules)
          ..where((t) =>
              t.projectId.equals(projectId) &
              t.date.isBiggerOrEqualValue(fromDate) &
              t.locked.equals(false)))
        .go();
  }

}
