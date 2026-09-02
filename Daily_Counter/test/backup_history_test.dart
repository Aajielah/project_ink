import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/backup_service.dart';
import 'package:daily_counter/core/utils/duration_utils.dart';
import 'package:daily_counter/shared/models/project.dart';
import 'package:daily_counter/shared/models/daily_record.dart';
import 'package:daily_counter/shared/models/pause.dart';
import 'package:daily_counter/shared/models/target_change_log.dart';
import 'package:daily_counter/shared/models/settings.dart';

void main() {
  late Directory tempDir1;
  late Directory tempDir2;
  late Isar isar1;
  late Isar isar2;
  late DatabaseService dbService1;
  late DatabaseService dbService2;

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}
  });

  setUp(() async {
    tempDir1 = Directory.systemTemp.createTempSync('isar_backup_source');
    tempDir2 = Directory.systemTemp.createTempSync('isar_backup_target');

    isar1 = await Isar.open(
      [
        ProjectSchema,
        DailyRecordSchema,
        PauseSchema,
        TargetChangeLogSchema,
        SettingsSchema,
      ],
      name: 'backup_source',
      directory: tempDir1.path,
    );
    dbService1 = DatabaseService(isar1);

    // Initialize default settings in dbService1
    final s1 = Settings()
      ..id = 1
      ..reminderTime = DateTime(2026, 1, 1, 21, 30)
      ..themeMode = 'dark'
      ..language = 'en'
      ..backupVersion = 1;
    await dbService1.saveSettings(s1);

    isar2 = await Isar.open(
      [
        ProjectSchema,
        DailyRecordSchema,
        PauseSchema,
        TargetChangeLogSchema,
        SettingsSchema,
      ],
      name: 'backup_target',
      directory: tempDir2.path,
    );
    dbService2 = DatabaseService(isar2);
  });

  tearDown(() async {
    await isar1.close();
    await isar2.close();
    tempDir1.deleteSync(recursive: true);
    tempDir2.deleteSync(recursive: true);
  });

  group('BackupService AES-256 Encryption & Restoration Tests', () {
    test('Exports and imports encrypted database with password match', () async {
      final start = DurationUtils.normalizeDate(DateTime(2026, 9, 1));
      final project = Project()
        ..title = 'Encrypted Goal'
        ..category = 'Faith'
        ..motivation = 'Spiritual discipline'
        ..targetDays = 40
        ..completedDays = 3
        ..trackingMode = 'trust'
        ..status = 'active'
        ..startDate = start
        ..endDate = DateTime(2026, 10, 10)
        ..createdAt = start
        ..updatedAt = start
        ..reminderEnabled = true;

      final pId = await dbService1.saveProject(project);

      final record = DailyRecord()
        ..projectId = pId
        ..date = start
        ..status = 'completed'
        ..automatic = false
        ..modified = false
        ..createdAt = start;
      await dbService1.saveRecord(record);

      final pause = Pause()
        ..projectId = pId
        ..startDate = start
        ..reason = 'Retreat';
      await dbService1.savePause(pause);

      final log = TargetChangeLog()
        ..projectId = pId
        ..oldTarget = 30
        ..newTarget = 40
        ..dateChanged = start;
      await dbService1.saveTargetChangeLog(log);

      // 1. Export with AES-256 password
      const password = 'SuperSecretPassword123!';
      final encryptedString = await BackupService.exportEncryptedBackup(dbService1, password);

      expect(encryptedString.isNotEmpty, isTrue);
      expect(encryptedString.contains('Encrypted Goal'), isFalse); // Verify it is ciphertext, not plaintext

      // 2. Import into empty dbService2 with correct password
      final importSuccess = await BackupService.importEncryptedBackup(
        dbService2,
        encryptedString,
        password,
      );
      expect(importSuccess, isTrue);

      // 3. Verify restored data in dbService2
      final restoredProjects = await dbService2.getAllProjects();
      expect(restoredProjects.length, equals(1));
      expect(restoredProjects.first.title, equals('Encrypted Goal'));
      expect(restoredProjects.first.category, equals('Faith'));
      expect(restoredProjects.first.targetDays, equals(40));

      final restoredRecords = await dbService2.getRecordsForProject(restoredProjects.first.id);
      expect(restoredRecords.length, equals(1));
      expect(restoredRecords.first.status, equals('completed'));

      final restoredPauses = await dbService2.getPausesForProject(restoredProjects.first.id);
      expect(restoredPauses.length, equals(1));
      expect(restoredPauses.first.reason, equals('Retreat'));

      final restoredLogs = await dbService2.getLogsForProject(restoredProjects.first.id);
      expect(restoredLogs.length, equals(1));
      expect(restoredLogs.first.newTarget, equals(40));

      final restoredSettings = await dbService2.getSettings();
      expect(restoredSettings.themeMode, equals('dark'));
    });

    test('Import fails gracefully when wrong password is provided', () async {
      final project = Project()
        ..title = 'Secure Project'
        ..category = 'Work'
        ..motivation = 'Work hard'
        ..targetDays = 20
        ..completedDays = 0
        ..trackingMode = 'strict'
        ..status = 'active'
        ..startDate = DateTime.now()
        ..endDate = DateTime.now().add(const Duration(days: 20))
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..reminderEnabled = true;

      await dbService1.saveProject(project);

      final encryptedString = await BackupService.exportEncryptedBackup(
        dbService1,
        'CorrectPassword123',
      );

      // Attempt to import with wrong password
      final importResult = await BackupService.importEncryptedBackup(
        dbService2,
        encryptedString,
        'WrongPassword456',
      );

      expect(importResult, isFalse);
      final projectsInDb2 = await dbService2.getAllProjects();
      expect(projectsInDb2, isEmpty); // Ensure no corrupt data was written
    });
  });
}
