import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class ChapterRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ChapterRepository(this._db);

  Stream<List<Chapter>> watchChaptersByProject(String projectId) {
    return (_db.select(_db.chapters)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  Future<List<Chapter>> getChaptersByProject(String projectId) {
    return (_db.select(_db.chapters)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  Future<Chapter> createChapter(String projectId, [String? customTitle]) async {
    final existing = await getChaptersByProject(projectId);
    final count = existing.length;
    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : 'Chapter ${count + 1}';

    final chapter = Chapter(
      id: _uuid.v4(),
      projectId: projectId,
      title: title,
      orderIndex: count,
      startBeat: '',
      middleBeat: '',
      endBeat: '',
      createdAt: DateTime.now(),
    );

    await _db.into(_db.chapters).insert(chapter);
    return chapter;
  }

  Future<void> updateChapterTitle(String id, String newTitle) async {
    await (_db.update(_db.chapters)..where((t) => t.id.equals(id))).write(
      ChaptersCompanion(
        title: Value(newTitle.trim()),
      ),
    );
  }

  Future<void> updateChapterBeats({
    required String id,
    String? startBeat,
    String? middleBeat,
    String? endBeat,
  }) async {
    await (_db.update(_db.chapters)..where((t) => t.id.equals(id))).write(
      ChaptersCompanion(
        startBeat: startBeat != null ? Value(startBeat) : const Value.absent(),
        middleBeat: middleBeat != null ? Value(middleBeat) : const Value.absent(),
        endBeat: endBeat != null ? Value(endBeat) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteChapter(String id) async {
    await (_db.delete(_db.chapters)..where((t) => t.id.equals(id))).go();
  }
}
