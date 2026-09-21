import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class LoreRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  LoreRepository(this._db);

  Stream<List<LoreEntry>> watchLoreEntries(String universeId) {
    return (_db.select(_db.loreEntries)
          ..where((l) => l.universeId.equals(universeId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<LoreEntry>> getLoreEntries(String universeId) {
    return (_db.select(_db.loreEntries)
          ..where((l) => l.universeId.equals(universeId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<LoreEntry?> getLoreEntry(String id) {
    return (_db.select(_db.loreEntries)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<LoreEntry> createLoreEntry({
    required String universeId,
    required String title,
    required String category,
    String? summary,
    String? content,
    String? tags,
  }) async {
    final now = DateTime.now();
    final companion = LoreEntriesCompanion(
      id: Value(_uuid.v4()),
      universeId: Value(universeId),
      title: Value(title.trim()),
      category: Value(category.trim()),
      summary: Value(summary?.trim()),
      content: Value(content?.trim()),
      tags: Value(tags?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    return await _db.into(_db.loreEntries).insertReturning(companion);
  }

  Future<void> updateLoreEntry({
    required String id,
    required String title,
    required String category,
    String? summary,
    String? content,
    String? tags,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.loreEntries)..where((l) => l.id.equals(id))).write(
      LoreEntriesCompanion(
        title: Value(title.trim()),
        category: Value(category.trim()),
        summary: Value(summary?.trim()),
        content: Value(content?.trim()),
        tags: Value(tags?.trim()),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteLoreEntry(String id) async {
    await (_db.delete(_db.loreEntries)..where((l) => l.id.equals(id))).go();
  }
}
