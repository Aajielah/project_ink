import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class SparkRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SparkRepository(this._db);

  Stream<List<IdeaSpark>> watchSparks(String universeId) {
    return (_db.select(_db.ideaSparks)
          ..where((s) => s.universeId.equals(universeId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.isPinned, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<IdeaSpark>> getSparks(String universeId) {
    return (_db.select(_db.ideaSparks)
          ..where((s) => s.universeId.equals(universeId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.isPinned, mode: OrderingMode.desc),
            (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<IdeaSpark?> getSpark(String id) {
    return (_db.select(_db.ideaSparks)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<IdeaSpark> createSpark({
    required String universeId,
    required String content,
    String category = 'General',
    bool isPinned = false,
  }) async {
    final companion = IdeaSparksCompanion(
      id: Value(_uuid.v4()),
      universeId: Value(universeId),
      content: Value(content.trim()),
      category: Value(category.trim()),
      isPinned: Value(isPinned),
      isConverted: const Value(false),
      createdAt: Value(DateTime.now()),
    );

    return await _db.into(_db.ideaSparks).insertReturning(companion);
  }

  Future<void> updateSpark({
    required String id,
    required String content,
    String? category,
  }) async {
    await (_db.update(_db.ideaSparks)..where((s) => s.id.equals(id))).write(
      IdeaSparksCompanion(
        content: Value(content.trim()),
        category: category != null ? Value(category.trim()) : const Value.absent(),
      ),
    );
  }

  Future<void> togglePin(String id, bool isPinned) async {
    await (_db.update(_db.ideaSparks)..where((s) => s.id.equals(id))).write(
      IdeaSparksCompanion(
        isPinned: Value(isPinned),
      ),
    );
  }

  Future<void> markConverted(String id, bool isConverted) async {
    await (_db.update(_db.ideaSparks)..where((s) => s.id.equals(id))).write(
      IdeaSparksCompanion(
        isConverted: Value(isConverted),
      ),
    );
  }

  Future<void> deleteSpark(String id) async {
    await (_db.delete(_db.ideaSparks)..where((s) => s.id.equals(id))).go();
  }
}
