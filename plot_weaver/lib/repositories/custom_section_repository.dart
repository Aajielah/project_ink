import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class CustomSectionRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CustomSectionRepository(this._db);

  Stream<List<CustomSection>> watchCustomSectionsByProject(String projectId) {
    return (_db.select(_db.customSections)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  Future<List<CustomSection>> getCustomSectionsByProject(String projectId) {
    return (_db.select(_db.customSections)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
  }

  Future<CustomSection> createCustomSection(String projectId, String title) async {
    final existing = await getCustomSectionsByProject(projectId);
    final count = existing.length;

    final section = CustomSection(
      id: _uuid.v4(),
      projectId: projectId,
      title: title.trim().isNotEmpty ? title.trim() : 'Custom Section ${count + 1}',
      content: '',
      orderIndex: count,
      createdAt: DateTime.now(),
    );

    await _db.into(_db.customSections).insert(section);
    return section;
  }

  Future<void> updateCustomSectionTitle(String id, String newTitle) async {
    await (_db.update(_db.customSections)..where((t) => t.id.equals(id))).write(
      CustomSectionsCompanion(
        title: Value(newTitle.trim()),
      ),
    );
  }

  Future<void> updateCustomSectionContent(String id, String content) async {
    await (_db.update(_db.customSections)..where((t) => t.id.equals(id))).write(
      CustomSectionsCompanion(
        content: Value(content),
      ),
    );
  }

  Future<void> deleteCustomSection(String id) async {
    await (_db.delete(_db.customSections)..where((t) => t.id.equals(id))).go();
  }
}
