import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/day_finalizer_service.dart';
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
    tempDir = Directory.systemTemp.createTempSync('isar_finalizer_test');
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

  group('DayFinalizerService 5:00 AM Grace Period & Finalization Tests', () {
    test('getLogicalTrackingDate respects 5:00 AM grace period', () {
      // 3:30 AM on Sept 10 -> logical date is Sept 9
      final earlyMorning = DateTime(2026, 9, 10, 3, 30);
      expect(
        DayFinalizerService.getLogicalTrackingDate(earlyMorning),
        equals(DateTime(2026, 9, 9)),
      );

      // 6:00 AM on Sept 10 -> logical date is Sept 10
      final afterCutoff = DateTime(2026, 9, 10, 6, 0);
      expect(
        DayFinalizerService.getLogicalTrackingDate(afterCutoff),
        equals(DateTime(2026, 9, 10)),
      );
    });

    test('Strict mode finalizes unrecorded past days as missed', () async {
      final start = DateTime(2026, 9, 1);
      final simulatedNow = DateTime(2026, 9, 4, 8, 0); // Past 5 AM on Day 4

      final strictProject = Project()
        ..title = 'Strict Gym'
        ..category = 'Fitness'
        ..motivation = 'No excuses'
        ..targetDays = 30
        ..completedDays = 0
        ..trackingMode = 'strict'
        ..status = 'active'
        ..startDate = start
        ..endDate = DateTime(2026, 9, 30)
        ..createdAt = start
        ..updatedAt = start
        ..reminderEnabled = true;

      final id = await dbService.saveProject(strictProject);

      // Finalize past days (Sept 1, 2, 3 should be marked missed)
      final processed = await DayFinalizerService.finalizePastDays(dbService, currentTime: simulatedNow);
      expect(processed, equals(3));

      final records = await dbService.getRecordsForProject(id);
      expect(records.length, equals(3));
      for (var r in records) {
        expect(r.status, equals('missed'));
        expect(r.automatic, isTrue);
      }

      final updatedProject = await dbService.getProject(id);
      expect(updatedProject!.completedDays, equals(0));
      expect(updatedProject.status, equals('active'));
    });

    test('Trust mode finalizes unrecorded past days as completed and auto-completes target', () async {
      final start = DateTime(2026, 9, 1);
      final simulatedNow = DateTime(2026, 9, 4, 8, 0); // 3 days elapsed: Sept 1, 2, 3

      final trustProject = Project()
        ..title = 'Trust Reading'
        ..category = 'Reading'
        ..motivation = 'Read daily'
        ..targetDays = 3 // Target is 3 days
        ..completedDays = 0
        ..trackingMode = 'trust'
        ..status = 'active'
        ..startDate = start
        ..endDate = DateTime(2026, 9, 3)
        ..createdAt = start
        ..updatedAt = start
        ..reminderEnabled = true;

      final id = await dbService.saveProject(trustProject);

      // Finalize past days (Sept 1, 2, 3 should be marked completed)
      final processed = await DayFinalizerService.finalizePastDays(dbService, currentTime: simulatedNow);
      expect(processed, equals(3));

      final records = await dbService.getRecordsForProject(id);
      expect(records.length, equals(3));
      for (var r in records) {
        expect(r.status, equals('completed'));
        expect(r.automatic, isTrue);
      }

      final updatedProject = await dbService.getProject(id);
      expect(updatedProject!.completedDays, equals(3));
      expect(updatedProject.status, equals('completed')); // Reached target of 3 days
    });
  });
}
