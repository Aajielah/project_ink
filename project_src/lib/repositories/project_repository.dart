import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/project.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  ProjectModel _mapToModel(Project data) {
    return ProjectModel(
      id: data.id,
      name: data.name,
      description: data.description,
      status: ProjectStatus.values.byName(data.status),
      projectType: ProjectType.values.byName(data.projectType),
      targetWords: data.targetWords,
      writtenWords: data.writtenWords,
      remainingWords: data.remainingWords,
      dailyWordTarget: data.dailyWordTarget,
      backlogWords: data.backlogWords,
      startDate: data.startDate,
      expectedFinishDate: data.expectedFinishDate,
      actualFinishDate: data.actualFinishDate,
      restMode: parseRestMode(data.restMode),
      allowedRestDays: data.allowedRestDays,
      remainingRestDays: data.remainingRestDays,
      projectStreak: data.projectStreak,
      longestProjectStreak: data.longestProjectStreak,
      currentWeek: data.currentWeek,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      coverImagePath: data.coverImagePath,
      coverType: data.coverType,
      pendingCarryForward: data.pendingCarryForward,
      ongoingStyle: data.ongoingStyle ?? 'daily',
      writingSession: data.writingSession ?? 'none',
      frozenDate: data.frozenDate,
      freezeActivatedAt: data.freezeActivatedAt,
    );
  }

  ProjectsCompanion _mapToCompanion(ProjectModel model) {
    return ProjectsCompanion(
      id: Value(model.id),
      name: Value(model.name),
      description: Value(model.description),
      status: Value(model.status.name),
      projectType: Value(model.projectType.name),
      targetWords: Value(model.targetWords),
      writtenWords: Value(model.writtenWords),
      remainingWords: Value(model.remainingWords),
      dailyWordTarget: Value(model.dailyWordTarget),
      backlogWords: Value(model.backlogWords),
      startDate: Value(model.startDate),
      expectedFinishDate: Value(model.expectedFinishDate),
      actualFinishDate: Value(model.actualFinishDate),
      restMode: Value(model.restMode.name),
      allowedRestDays: Value(model.allowedRestDays),
      remainingRestDays: Value(model.remainingRestDays),
      projectStreak: Value(model.projectStreak),
      longestProjectStreak: Value(model.longestProjectStreak),
      currentWeek: Value(model.currentWeek),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      coverImagePath: Value(model.coverImagePath),
      coverType: Value(model.coverType),
      pendingCarryForward: Value(model.pendingCarryForward),
      ongoingStyle: Value(model.ongoingStyle),
      writingSession: Value(model.writingSession),
      frozenDate: Value(model.frozenDate),
      freezeActivatedAt: Value(model.freezeActivatedAt),
    );
  }


  Future<List<ProjectModel>> getAllProjects() async {
    final query = _db.select(_db.projects);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  Future<ProjectModel?> getProjectById(String id) async {
    final query = _db.select(_db.projects)..where((t) => t.id.equals(id));
    final data = await query.getSingleOrNull();
    return data != null ? _mapToModel(data) : null;
  }

  Future<void> insertProject(ProjectModel project) async {
    await _db.into(_db.projects).insert(_mapToCompanion(project));
  }

  Future<void> updateProject(ProjectModel project) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(project.id)))
        .write(_mapToCompanion(project));
  }

  Future<void> deleteProject(String id) async {
    await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
  }
}
