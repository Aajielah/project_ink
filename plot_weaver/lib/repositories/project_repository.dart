import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class ProjectRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ProjectRepository(this._db);

  Stream<List<Project>> watchAllProjects() {
    return (_db.select(_db.projects)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Project>> watchProjectsByBook(String bookId) {
    return (_db.select(_db.projects)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<Project>> watchUnassignedProjects() {
    return (_db.select(_db.projects)
          ..where((t) => t.bookId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<Project?> watchProject(String id) {
    return (_db.select(_db.projects)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<Project?> getProject(String id) {
    return (_db.select(_db.projects)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Project> createProject({
    required String name,
    required String genre,
    String? bookId,
  }) async {
    final now = DateTime.now();
    final projectId = _uuid.v4();

    final project = Project(
      id: projectId,
      bookId: bookId,
      name: name.trim(),
      genre: genre.trim(),
      generalIdea: '',
      createdAt: now,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.into(_db.projects).insert(project);

      // Starter Arc 1
      await _db.into(_db.arcs).insert(
            ArcsCompanion.insert(
              id: _uuid.v4(),
              projectId: projectId,
              title: 'Arc 1',
              content: const Value(''),
              orderIndex: 0,
              createdAt: now,
            ),
          );

      // Starter Chapter 1 with 3-beat template
      await _db.into(_db.chapters).insert(
            ChaptersCompanion.insert(
              id: _uuid.v4(),
              projectId: projectId,
              title: 'Chapter 1',
              orderIndex: 0,
              startBeat: const Value(''),
              middleBeat: const Value(''),
              endBeat: const Value(''),
              createdAt: now,
            ),
          );
    });

    return project;
  }

  Future<void> updateGeneralIdea(String projectId, String text) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(projectId))).write(
      ProjectsCompanion(
        generalIdea: Value(text),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProjectInfo({
    required String id,
    required String name,
    required String genre,
    String? bookId,
  }) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        name: Value(name.trim()),
        genre: Value(genre.trim()),
        bookId: Value(bookId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> assignProjectToBook(String projectId, String? bookId) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(projectId))).write(
      ProjectsCompanion(
        bookId: Value(bookId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProject(String id) async {
    await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
  }
}
