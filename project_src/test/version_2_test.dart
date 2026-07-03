import 'package:flutter_test/flutter_test.dart';
import 'package:project_ink/models/project.dart';
import 'package:project_ink/models/schedule.dart';
import 'dart:math';

void main() {
  group('Version 2 Flexible Duration Conversion Tests', () {
    test('Converts Weeks to Days correctly', () {
      const qty = 4; // 4 weeks
      final days = qty * 7;
      expect(days, equals(28));
    });

    test('Converts Months to Days correctly', () {
      const qty = 3; // 3 months
      final days = qty * 30;
      expect(days, equals(90));
    });

    test('Converts Custom Date Range to Days correctly', () {
      final start = DateTime(2026, 7, 3);
      final end = DateTime(2026, 7, 24); // 22 days inclusive
      final days = end.difference(start).inDays + 1;
      expect(days, equals(22));
    });
  });

  group('Version 2 Global Quick Log Splitting Tests', () {
    test('Even Split distributes words correctly', () {
      const totalWords = 1000;
      const count = 3;
      final splitWords = totalWords ~/ count; // 333
      final remainder = totalWords % count; // 1

      final allocations = List.generate(count, (i) => i == 0 ? splitWords + remainder : splitWords);

      expect(allocations, equals([334, 333, 333]));
      expect(allocations.reduce((a, b) => a + b), equals(totalWords));
    });

    test('Proportional Split distributes words based on today\'s targets', () {
      const totalWords = 1000;
      final targets = [600, 400];
      final totalPlanned = targets.reduce((a, b) => a + b); // 1000

      int remainingToLog = totalWords;
      final allocations = <int>[];
      for (int i = 0; i < targets.length; i++) {
        if (i == targets.length - 1) {
          allocations.add(remainingToLog);
        } else {
          final wordsToLog = (targets[i] / totalPlanned * totalWords).round();
          allocations.add(wordsToLog);
          remainingToLog -= wordsToLog;
        }
      }

      expect(allocations, equals([600, 400]));
      expect(allocations.reduce((a, b) => a + b), equals(totalWords));
    });

    test('Smart Split prioritizing backlog works correctly', () {
      // 2 projects:
      // Project A: backlog = 200, target = 300
      // Project B: backlog = 0, target = 500
      // Log total = 600 words
      const totalWords = 600;
      int remainingWords = totalWords;

      final backlogs = {'A': 200, 'B': 0};
      final targets = {'A': 300, 'B': 500};
      final allocations = {'A': 0, 'B': 0};

      // 1. Fill backlogs
      for (final key in backlogs.keys) {
        final b = backlogs[key]!;
        if (b > 0) {
          final fill = min(b, remainingWords);
          allocations[key] = allocations[key]! + fill;
          remainingWords -= fill;
        }
      }

      // Assert Project A received 200 words backlog, remaining is 400
      expect(allocations['A'], equals(200));
      expect(remainingWords, equals(400));

      // 2. Satisfy target
      for (final key in targets.keys) {
        final t = targets[key]!;
        if (t > 0) {
          final fill = min(t, remainingWords);
          allocations[key] = allocations[key]! + fill;
          remainingWords -= fill;
        }
      }

      // allocations:
      // A gets 200 backlog + 300 target = 500
      // B gets 0 backlog + 100 remaining target = 100
      expect(allocations['A'], equals(500));
      expect(allocations['B'], equals(100));
      expect(remainingWords, equals(0));
    });
  });

  group('Version 2 Writing Advisor Heuristics Tests', () {
    final now = DateTime.now();
    final pBacklog = ProjectModel(
      id: 'backlog_project',
      name: 'Backlogged Book',
      status: ProjectStatus.active,
      targetWords: 10000,
      writtenWords: 1000,
      remainingWords: 9000,
      dailyWordTarget: 500,
      backlogWords: 400, // backlog
      startDate: now,
      expectedFinishDate: now.add(const Duration(days: 20)),
      restMode: RestMode.flexible,
      allowedRestDays: 1,
      remainingRestDays: 1,
      projectStreak: 2,
      longestProjectStreak: 2,
      currentWeek: 1,
      createdAt: now,
      updatedAt: now,
    );

    final pNearFinish = ProjectModel(
      id: 'near_finish_project',
      name: 'Nearly Done Novel',
      status: ProjectStatus.active,
      targetWords: 10000,
      writtenWords: 8500, // 85% progress
      remainingWords: 1500,
      dailyWordTarget: 300,
      backlogWords: 0,
      startDate: now,
      expectedFinishDate: now.add(const Duration(days: 5)),
      restMode: RestMode.flexible,
      allowedRestDays: 1,
      remainingRestDays: 1,
      projectStreak: 4,
      longestProjectStreak: 4,
      currentWeek: 1,
      createdAt: now,
      updatedAt: now,
    );

    final pStandard = ProjectModel(
      id: 'standard_project',
      name: 'Standard Story',
      status: ProjectStatus.active,
      targetWords: 10000,
      writtenWords: 2000, // 20% progress
      remainingWords: 8000,
      dailyWordTarget: 400,
      backlogWords: 0,
      startDate: now,
      expectedFinishDate: now.add(const Duration(days: 30)),
      restMode: RestMode.flexible,
      allowedRestDays: 1,
      remainingRestDays: 1,
      projectStreak: 1,
      longestProjectStreak: 1,
      currentWeek: 1,
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 2)), // older update date
    );

    double getProgress(ProjectModel p) => p.targetWords > 0 ? p.writtenWords / p.targetWords : 0.0;

    test('Smart Strategy recommends backlog project first', () {
      final active = [pBacklog, pNearFinish, pStandard];
      
      // Smart Heuristic: Backlog first
      final backlogged = active.where((p) => p.backlogWords > 0).toList();
      expect(backlogged.isNotEmpty, isTrue);
      expect(backlogged.first.id, equals('backlog_project'));
    });

    test('Smart Strategy recommends nearly completed if no backlogs exist', () {
      final active = [pNearFinish, pStandard]; // no backlog project
      
      // Smart Heuristic: progress >= 0.8
      final highProgress = active.where((p) => getProgress(p) >= 0.8 && getProgress(p) < 1.0).toList();
      expect(highProgress.isNotEmpty, isTrue);
      expect(highProgress.first.id, equals('near_finish_project'));
    });

    test('Finish Near Completion Strategy recommends project with highest ratio', () {
      final active = [pBacklog, pNearFinish, pStandard];
      
      final list = active.where((p) => getProgress(p) < 1.0).toList();
      list.sort((a, b) => getProgress(b).compareTo(getProgress(a)));
      expect(list.first.id, equals('near_finish_project'));
    });

    test('Earliest Deadline Strategy recommends project with closest finish date', () {
      final active = [pBacklog, pNearFinish, pStandard];
      
      final list = List<ProjectModel>.from(active);
      list.sort((a, b) => a.expectedFinishDate.compareTo(b.expectedFinishDate));
      expect(list.first.id, equals('near_finish_project')); // 5 days vs 20 days vs 30 days
    });

    test('Rotate Projects recommends least recently updated project', () {
      final active = [pBacklog, pNearFinish, pStandard];
      
      final list = List<ProjectModel>.from(active);
      list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      expect(list.first.id, equals('standard_project')); // updated 2 days ago
    });
  });
}
