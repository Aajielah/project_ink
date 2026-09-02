import 'package:flutter_test/flutter_test.dart';
import 'package:project_ink/models/project.dart';
import 'package:project_ink/features/projects/projects_screen.dart';

ProjectModel makeProject({
  required String id,
  required String name,
  required ProjectStatus status,
  required String groupId,
  int targetWords = 50000,
  int writtenWords = 0,
  int remainingWords = 50000,
  DateTime? actualFinishDate,
}) {
  final now = DateTime(2026, 9, 1);
  return ProjectModel(
    id: id,
    name: name,
    status: status,
    groupId: groupId,
    targetWords: targetWords,
    writtenWords: writtenWords,
    remainingWords: remainingWords,
    dailyWordTarget: 1000,
    backlogWords: 0,
    startDate: now,
    expectedFinishDate: now.add(const Duration(days: 30)),
    actualFinishDate: actualFinishDate,
    restMode: RestMode.fixed,
    allowedRestDays: 4,
    remainingRestDays: 4,
    projectStreak: 0,
    longestProjectStreak: 0,
    currentWeek: 1,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Project Grouping Tests', () {
    test('Single project forms single group without multiple runs', () {
      final p1 = makeProject(
        id: 'p1',
        name: 'My Book',
        status: ProjectStatus.active,
        groupId: 'g1',
      );

      final groups = groupProjectsList([p1]);
      expect(groups.length, 1);
      expect(groups.first.groupId, 'g1');
      expect(groups.first.runningProject?.id, 'p1');
      expect(groups.first.hasMultipleRuns, false);
      expect(groups.first.hasCompletedRuns, false);
    });

    test('Completed run and running run group together into 1 card in Active tab', () {
      final p1 = makeProject(
        id: 'p1',
        name: 'Book Vol 1',
        writtenWords: 50000,
        remainingWords: 0,
        actualFinishDate: DateTime(2026, 8, 31),
        status: ProjectStatus.completed,
        groupId: 'series_1',
      );

      final p2 = makeProject(
        id: 'p2',
        name: 'Book Vol 2',
        writtenWords: 5000,
        remainingWords: 45000,
        status: ProjectStatus.active,
        groupId: 'series_1',
      );

      final groups = groupProjectsList([p1, p2]);
      expect(groups.length, 1);
      final group = groups.first;

      expect(group.runningProject?.id, 'p2');
      expect(group.completedProjects.length, 1);
      expect(group.completedProjects.first.id, 'p1');
      expect(group.hasMultipleRuns, true);
      expect(group.totalWordsAllRuns, 55000);
      expect(group.primaryProject.id, 'p2');
    });

    test('All completed runs group into Completed tab with start next run capability', () {
      final p1 = makeProject(
        id: 'p1',
        name: 'Book Vol 1',
        writtenWords: 50000,
        remainingWords: 0,
        actualFinishDate: DateTime(2026, 7, 31),
        status: ProjectStatus.completed,
        groupId: 'series_2',
      );

      final p2 = makeProject(
        id: 'p2',
        name: 'Book Vol 2',
        writtenWords: 50000,
        remainingWords: 0,
        actualFinishDate: DateTime(2026, 8, 31),
        status: ProjectStatus.completed,
        groupId: 'series_2',
      );

      final groups = groupProjectsList([p1, p2]);
      expect(groups.length, 1);
      final group = groups.first;

      expect(group.runningProject, isNull);
      expect(group.completedProjects.length, 2);
      expect(group.hasMultipleRuns, true);
      expect(group.totalWordsAllRuns, 100000);
    });
  });
}
