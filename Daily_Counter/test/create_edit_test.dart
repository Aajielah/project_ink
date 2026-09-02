import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/utils/duration_utils.dart';
import 'package:daily_counter/core/utils/motivation_utils.dart';
import 'package:daily_counter/shared/models/project.dart';
import 'package:daily_counter/shared/models/daily_record.dart';
import 'package:daily_counter/shared/models/pause.dart';
import 'package:daily_counter/shared/models/target_change_log.dart';
import 'package:daily_counter/shared/models/settings.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late DatabaseService dbService;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_create_edit_test');
    isar = await Isar.open(
      [
        ProjectSchema,
        DailyRecordSchema,
        PauseSchema,
        TargetChangeLogSchema,
        SettingsSchema,
      ],
      directory: tempDir.path,
    );
    dbService = DatabaseService(isar);
  });

  tearDown(() async {
    await isar.close();
    tempDir.deleteSync(recursive: true);
  });

  group('DurationUtils & MotivationUtils Tests', () {
    test('calculateTotalDays converts units accurately', () {
      final start = DateTime(2026, 9, 1);
      
      expect(DurationUtils.calculateTotalDays(unit: 'Days', value: 30, startDate: start), equals(30));
      expect(DurationUtils.calculateTotalDays(unit: 'Weeks', value: 12, startDate: start), equals(84));
      expect(DurationUtils.calculateTotalDays(unit: 'Years', value: 1, startDate: start), equals(365));
      
      final customEnd = DateTime(2026, 9, 10);
      expect(
        DurationUtils.calculateTotalDays(unit: 'Custom Range', value: 0, startDate: start, customEndDate: customEnd),
        equals(10),
      );
    });

    test('Motivation templates are populated for all standard categories', () {
      for (var category in MotivationUtils.categories) {
        final quote = MotivationUtils.getDefaultMotivation(category);
        expect(quote.isNotEmpty, isTrue);
      }
    });
  });

  group('Project Creation, Target Revision, and Lifecycle Tests', () {
    test('Creates a project and logs target change upon revision', () async {
      final start = DurationUtils.normalizeDate(DateTime(2026, 9, 1));
      final initialDays = 30;
      final initialEnd = DurationUtils.calculateEndDate(start, initialDays);

      final project = Project()
        ..title = 'Read 10 Books'
        ..category = 'Reading'
        ..motivation = 'Reading expands perspective.'
        ..targetDays = initialDays
        ..completedDays = 0
        ..trackingMode = 'strict'
        ..status = 'active'
        ..startDate = start
        ..endDate = initialEnd
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..reminderEnabled = true;

      final projectId = await dbService.saveProject(project);
      expect(projectId, isNotNull);

      // Verify initial project
      final fetched = await dbService.getProject(projectId);
      expect(fetched, isNotNull);
      expect(fetched!.targetDays, equals(30));
      expect(fetched.endDate, equals(initialEnd));

      // Simulate Target Days Revision: 30 -> 60 days
      final newTargetDays = 60;
      final newEnd = DurationUtils.calculateEndDate(start, newTargetDays);
      
      final changeLog = TargetChangeLog()
        ..projectId = projectId
        ..oldTarget = 30
        ..newTarget = newTargetDays
        ..dateChanged = DateTime.now();
      await dbService.saveTargetChangeLog(changeLog);

      fetched.targetDays = newTargetDays;
      fetched.endDate = newEnd;
      await dbService.saveProject(fetched);

      // Verify Target Revision in DB
      final logs = await dbService.getLogsForProject(projectId);
      expect(logs.length, equals(1));
      expect(logs.first.oldTarget, equals(30));
      expect(logs.first.newTarget, equals(60));

      final updatedProject = await dbService.getProject(projectId);
      expect(updatedProject!.targetDays, equals(60));
      expect(updatedProject.endDate, equals(newEnd));
    });

    test('Pause and Resume lifecycle updates project status and pause records', () async {
      final start = DurationUtils.normalizeDate(DateTime.now());
      final project = Project()
        ..title = 'Fitness Challenge'
        ..category = 'Fitness'
        ..motivation = 'Get fit'
        ..targetDays = 30
        ..completedDays = 5
        ..trackingMode = 'strict'
        ..status = 'active'
        ..startDate = start
        ..endDate = DurationUtils.calculateEndDate(start, 30)
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..reminderEnabled = true;

      final id = await dbService.saveProject(project);

      // 1. Pause Project
      final pause = Pause()
        ..projectId = id
        ..startDate = DateTime.now()
        ..reason = 'Traveling';
      await dbService.savePause(pause);

      project.status = 'paused';
      await dbService.saveProject(project);

      var checkProject = await dbService.getProject(id);
      expect(checkProject!.status, equals('paused'));

      var pauses = await dbService.getPausesForProject(id);
      expect(pauses.length, equals(1));
      expect(pauses.first.endDate, isNull);
      expect(pauses.first.reason, equals('Traveling'));

      // 2. Resume Project
      final activePause = pauses.first;
      activePause.endDate = DateTime.now().add(const Duration(days: 3));
      await dbService.savePause(activePause);

      project.status = 'active';
      project.endDate = project.endDate.add(const Duration(days: 3));
      await dbService.saveProject(project);

      checkProject = await dbService.getProject(id);
      expect(checkProject!.status, equals('active'));
    });
  });
}
