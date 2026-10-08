import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class ArcRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ArcRepository(this._db);

  Stream<List<Arc>> watchArcsByProject(String projectId) {
    return (_db.select(_db.arcs)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  Future<List<Arc>> getArcsByProject(String projectId) {
    return (_db.select(_db.arcs)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  Future<Arc> createArc(String projectId, [String? customTitle]) async {
    final existing = await getArcsByProject(projectId);
    final count = existing.length;
    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : 'Arc ${count + 1}';

    final arc = Arc(
      id: _uuid.v4(),
      projectId: projectId,
      title: title,
      content: '',
      orderIndex: count,
      createdAt: DateTime.now(),
    );

    await _db.into(_db.arcs).insert(arc);
    return arc;
  }

  Future<void> updateArcTitle(String id, String newTitle) async {
    await (_db.update(_db.arcs)..where((t) => t.id.equals(id))).write(
      ArcsCompanion(
        title: Value(newTitle.trim()),
      ),
    );
  }

  Future<void> updateArcContent(String id, String content) async {
    await (_db.update(_db.arcs)..where((t) => t.id.equals(id))).write(
      ArcsCompanion(
        content: Value(content),
      ),
    );
  }

  Future<void> deleteArc(String id) async {
    await (_db.delete(_db.arcs)..where((t) => t.id.equals(id))).go();
  }
}
