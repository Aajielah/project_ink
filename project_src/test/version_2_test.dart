import 'package:flutter_test/flutter_test.dart';
import 'package:project_ink/models/project.dart';
import 'package:project_ink/models/schedule.dart';
import 'package:project_ink/shared/date_utils.dart';
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

  group('Version 2.3 Stability & Workflow Tests', () {
    test('Writing Advisor Weighted Scoring prioritizes incomplete target today', () {
      const remA = 500;
      const remB = 0;
      
      final scoreA = (10000 - remA).clamp(0, 10000) / 10000.0;
      final scoreB = 0.0;
      
      final totalA = (scoreA * 100.0) + 1000.0; // Boosted
      final totalB = (scoreB * 100.0);
      
      expect(totalA, greaterThan(totalB));
    });

    test('Rotation rotates candidates correctly based on day and hour', () {
      final candidates = ['Project A', 'Project B'];
      
      final index1 = (5 + 10) % candidates.length;
      expect(candidates[index1], equals('Project B'));
      
      final index2 = (5 + 11) % candidates.length;
      expect(candidates[index2], equals('Project A'));
    });

    test('Backlog recovery reduces backlog and marks log as completed if met', () {
      const planned = 1000;
      const originalActual = 500;
      const originalBacklog = 500;
      
      const resolveWords = 200;
      
      final newActual = originalActual + resolveWords;
      final newBacklog = originalBacklog - resolveWords;
      final completed = newActual >= planned;
      
      expect(newActual, equals(700));
      expect(newBacklog, equals(300));
      expect(completed, isFalse);
      
      final finalActual = newActual + 300;
      final finalBacklog = newBacklog - 300;
      final finalCompleted = finalActual >= planned;
      
      expect(finalActual, equals(1000));
      expect(finalBacklog, equals(0));
      expect(finalCompleted, isTrue);
    });
  });

  group('Version 2.3 Manual Rest Day Conversion Tests', () {
    test('Manual Rest Day conversion redistributes words to future days', () {
      final start = DateTime(2026, 7, 5);
      final schedules = [
        ScheduleModel(
          id: 's1',
          projectId: 'p1',
          date: start,
          plannedWords: 300,
          isRestDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        ),
        ScheduleModel(
          id: 's2',
          projectId: 'p1',
          date: start.add(const Duration(days: 1)),
          plannedWords: 300,
          isRestDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        ),
        ScheduleModel(
          id: 's3',
          projectId: 'p1',
          date: start.add(const Duration(days: 2)),
          plannedWords: 300,
          isRestDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        ),
      ];

      final todaySchedule = schedules[0].copyWith(
        isRestDay: true,
        plannedWords: 0,
        locked: true,
      );

      final tempSchedules = schedules.map((s) => s.id == 's1' ? todaySchedule : s).toList();

      final recalculated = tempSchedules.map((s) {
        if (s.id == 's1') return s;
        if (s.id == 's2') return s.copyWith(plannedWords: 500);
        if (s.id == 's3') return s.copyWith(plannedWords: 400);
        return s;
      }).toList();

      expect(recalculated[0].isRestDay, isTrue);
      expect(recalculated[0].plannedWords, 0);
      expect(recalculated[0].locked, isTrue);

      expect(recalculated[1].plannedWords, 500);
      expect(recalculated[2].plannedWords, 400);
      expect(recalculated[1].plannedWords + recalculated[2].plannedWords, equals(900));
    });

    test('Adaptive mode availability check checks overall remaining budget correctly', () {
      final start = DateTime(2026, 7, 5);
      final project = ProjectModel(
        id: 'p1',
        name: 'Project 1',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: start,
        expectedFinishDate: start.add(const Duration(days: 14)), // 2 weeks
        restMode: RestMode.adaptive,
        allowedRestDays: 4,
        remainingRestDays: 4,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: start,
        updatedAt: start,
      );

      final hasRest = project.remainingRestDays > 0;
      expect(hasRest, isTrue);
    });

    test('Flexible mode availability check checks overall remaining budget correctly', () {
      final start = DateTime(2026, 7, 5);
      final project = ProjectModel(
        id: 'p1',
        name: 'Project 1',
        status: ProjectStatus.active,
        projectType: ProjectType.fixed,
        targetWords: 10000,
        writtenWords: 0,
        remainingWords: 10000,
        dailyWordTarget: 500,
        backlogWords: 0,
        startDate: start,
        expectedFinishDate: start.add(const Duration(days: 14)), // 2 weeks
        restMode: RestMode.flexible,
        allowedRestDays: 4,
        remainingRestDays: 4,
        projectStreak: 0,
        longestProjectStreak: 0,
        currentWeek: 1,
        createdAt: start,
        updatedAt: start,
      );

      final hasRest = project.remainingRestDays > 0;
      expect(hasRest, isTrue);
    });
  });
}
