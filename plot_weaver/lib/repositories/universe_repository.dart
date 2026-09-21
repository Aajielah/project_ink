import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class UniverseStats {
  final int characterCount;
  final int chapterCount;
  final int sceneCount;
  final int loreCount;
  final int sparkCount;
  final int totalEstimatedWords;

  const UniverseStats({
    required this.characterCount,
    required this.chapterCount,
    required this.sceneCount,
    required this.loreCount,
    required this.sparkCount,
    required this.totalEstimatedWords,
  });
}

class UniverseRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  UniverseRepository(this._db);

  Stream<List<Universe>> watchAllUniverses() {
    return (_db.select(_db.universes)
          ..orderBy([
            (u) => OrderingTerm(expression: u.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<Universe>> getAllUniverses() {
    return (_db.select(_db.universes)
          ..orderBy([
            (u) => OrderingTerm(expression: u.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<Universe?> getUniverse(String id) {
    return (_db.select(_db.universes)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Universe> createUniverse({
    required String title,
    required String genre,
    String? logline,
    String? synopsis,
    String coverColor = 'amber',
    String? linkedProjectInkId,
    String? linkedProjectInkName,
  }) async {
    final now = DateTime.now();
    final newUniverse = UniversesCompanion(
      id: Value(_uuid.v4()),
      title: Value(title.trim()),
      genre: Value(genre.trim()),
      logline: Value(logline?.trim()),
      synopsis: Value(synopsis?.trim()),
      coverColor: Value(coverColor),
      linkedProjectInkId: Value(linkedProjectInkId),
      linkedProjectInkName: Value(linkedProjectInkName),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final inserted = await _db.into(_db.universes).insertReturning(newUniverse);
    return inserted;
  }

  Future<void> updateUniverse({
    required String id,
    required String title,
    required String genre,
    String? logline,
    String? synopsis,
    String? coverColor,
    String? linkedProjectInkId,
    String? linkedProjectInkName,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.universes)..where((u) => u.id.equals(id))).write(
      UniversesCompanion(
        title: Value(title.trim()),
        genre: Value(genre.trim()),
        logline: Value(logline?.trim()),
        synopsis: Value(synopsis?.trim()),
        coverColor: coverColor != null ? Value(coverColor) : const Value.absent(),
        linkedProjectInkId: Value(linkedProjectInkId),
        linkedProjectInkName: Value(linkedProjectInkName),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteUniverse(String id) async {
    await (_db.delete(_db.universes)..where((u) => u.id.equals(id))).go();
  }

  Future<UniverseStats> getUniverseStats(String universeId) async {
    final characters = await (_db.select(_db.characters)
          ..where((c) => c.universeId.equals(universeId)))
        .get();

    final chapters = await (_db.select(_db.chapters)
          ..where((c) => c.universeId.equals(universeId)))
        .get();

    final scenes = await (_db.select(_db.scenes)
          ..where((s) => s.universeId.equals(universeId)))
        .get();

    final lore = await (_db.select(_db.loreEntries)
          ..where((l) => l.universeId.equals(universeId)))
        .get();

    final sparks = await (_db.select(_db.ideaSparks)
          ..where((s) => s.universeId.equals(universeId)))
        .get();

    final totalWords = chapters.fold<int>(
      0,
      (sum, chapter) => sum + chapter.estimatedWordCount,
    );

    return UniverseStats(
      characterCount: characters.length,
      chapterCount: chapters.length,
      sceneCount: scenes.length,
      loreCount: lore.length,
      sparkCount: sparks.length,
      totalEstimatedWords: totalWords,
    );
  }
}
