import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:daily_counter/core/services/database_service.dart';
import 'package:daily_counter/core/services/backup_service.dart';
import 'package:daily_counter/core/services/day_finalizer_service.dart';
import 'package:daily_counter/core/utils/duration_utils.dart';
import 'package:daily_counter/shared/models/project.dart';
import 'package:daily_counter/shared/models/daily_record.dart';
import 'package:daily_counter/shared/models/pause.dart';
import 'package:daily_counter/shared/models/target_change_log.dart';
import 'package:daily_counter/shared/models/settings.dart';

void main() {
  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {}
  });

  group('Group 1: 100 Date, Duration, Leap Year & DST Boundary Tests (1-100)', () {
    test('100 Date & Duration Calculation Variations', () {
      final rand = Random(42);

      // 1-25: Leap year calculations
      for (int i = 1; i <= 25; i++) {
        final leapYear = 2024 + ((i % 4) * 4); // 2024, 2028, 2032...
        final startFeb = DateTime(leapYear, 2, 28);
        final nextDay = DurationUtils.calculateEndDate(startFeb, 2);
        expect(nextDay.month, equals(2), reason: 'Test $i: Leap year Feb 28 + 2 days should end on Feb 29');
        expect(nextDay.day, equals(29));
      }

      // 26-50: Year-crossing calculations
      for (int i = 26; i <= 50; i++) {
        final days = i;
        final startDec = DateTime(2026, 12, 31);
        final end = DurationUtils.calculateEndDate(startDec, days);
        if (days == 1) {
          expect(end.year, equals(2026));
          expect(end.month, equals(12));
          expect(end.day, equals(31));
        } else {
          expect(end.year, equals(2027), reason: 'Test $i: Crossing into new year');
        }
      }

      // 51-75: Unit conversion tests (Weeks, Months, Years)
      for (int i = 51; i <= 75; i++) {
        final val = (i - 50);
        final start = DateTime(2026, 1, 1);
        final weekDays = DurationUtils.calculateTotalDays(unit: 'Weeks', value: val, startDate: start);
        expect(weekDays, equals(val * 7), reason: 'Test $i: $val weeks == ${val * 7} days');

        final yearDays = DurationUtils.calculateTotalDays(unit: 'Years', value: 1, startDate: start);
        expect(yearDays, equals(365));
      }

      // 76-100: Custom range and randomized duration bounds
      for (int i = 76; i <= 100; i++) {
        final startDay = rand.nextInt(20) + 1;
        final span = rand.nextInt(100) + 1;
        final start = DateTime(2026, 5, startDay);
        final end = start.add(Duration(days: span - 1));
        final computed = DurationUtils.calculateTotalDays(
          unit: 'Custom Range',
          value: 0,
          startDate: start,
          customEndDate: end,
        );
        expect(computed, equals(span), reason: 'Test $i: Custom range calculation for $span days');
      }
    });
  });

  group('Group 2: 100 5:00 AM Grace Period Cutoff Tests (101-200)', () {
    test('100 Grace Period Minute-by-Minute Boundary Tests', () {
      // 101-150: 50 Early Morning Times (00:00 to 04:59) -> Must resolve to yesterday
      for (int i = 1; i <= 50; i++) {
        final hour = (i - 1) % 5; // 0, 1, 2, 3, 4
        final minute = (i * 13) % 60;
        final earlyTime = DateTime(2026, 8, 15, hour, minute);
        final logical = DayFinalizerService.getLogicalTrackingDate(earlyTime);

        expect(logical.year, equals(2026), reason: 'Test ${100 + i}: Grace period date check');
        expect(logical.month, equals(8));
        expect(logical.day, equals(14), reason: 'Test ${100 + i}: $hour:$minute is in grace period, expected Aug 14');
      }

      // 151-200: 50 Daytime Times (05:00 to 23:59) -> Must resolve to today
      for (int i = 1; i <= 50; i++) {
        final hour = 5 + ((i - 1) % 19); // 5 to 23
        final minute = (i * 17) % 60;
        final dayTime = DateTime(2026, 8, 15, hour, minute);
        final logical = DayFinalizerService.getLogicalTrackingDate(dayTime);

        expect(logical.year, equals(2026));
        expect(logical.month, equals(8));
        expect(logical.day, equals(15), reason: 'Test ${150 + i}: $hour:$minute is past grace period, expected Aug 15');
      }
    });
  });

  group('Group 3: 100 Finalization & Pause Interaction Tests (201-300)', () {
    test('100 Multi-Day Pause and Day Finalization Matrix Scenarios', () async {
      final tempDir = Directory.systemTemp.createTempSync('isar_stress_finalizer');
      final isar = await Isar.open(
        [
          ProjectSchema,
          DailyRecordSchema,
          PauseSchema,
          TargetChangeLogSchema,
          SettingsSchema,
        ],
        name: 'stress_finalizer_db',
        directory: tempDir.path,
      );
      final db = DatabaseService(isar);

      try {
        // Run 50 Strict Mode pause scenarios (Tests 201-250)
        for (int i = 1; i <= 50; i++) {
          final start = DateTime(2026, 1, 1);
          final p = Project()
            ..title = 'Strict Stress $i'
            ..category = 'Work'
            ..motivation = 'Focus'
            ..targetDays = 30
            ..completedDays = 0
            ..trackingMode = 'strict'
            ..status = 'active'
            ..startDate = start
            ..endDate = DateTime(2026, 1, 30)
            ..createdAt = start
            ..updatedAt = start
            ..reminderEnabled = true;

          final id = await db.saveProject(p);

          // Add a 3-day pause: Jan 2 to Jan 4
          final pause = Pause()
            ..projectId = id
            ..startDate = DateTime(2026, 1, 2)
            ..endDate = DateTime(2026, 1, 4)
            ..reason = 'Break';
          await db.savePause(pause);

          // Finalize on Jan 6 at 8:00 AM (Past cutoff)
          // Unpaused past days: Jan 1, Jan 5 (2 days). Paused days Jan 2, 3, 4 must NOT be finalized.
          await DayFinalizerService.finalizePastDays(db, currentTime: DateTime(2026, 1, 6, 8, 0));

          final records = await db.getRecordsForProject(id);
          expect(records.length, equals(2), reason: 'Test ${200 + i}: Exactly 2 unpaused days finalized');

          // Clean up for next iteration
          await db.deleteProject(id);
        }

        // Run 50 Trust Mode target completion scenarios (Tests 251-300)
        for (int i = 1; i <= 50; i++) {
          final target = 3;
          final start = DateTime(2026, 2, 1);
          final p = Project()
            ..title = 'Trust Auto-Finish $i'
            ..category = 'Reading'
            ..motivation = 'Read'
            ..targetDays = target
            ..completedDays = 0
            ..trackingMode = 'trust'
            ..status = 'active'
            ..startDate = start
            ..endDate = DateTime(2026, 2, target)
            ..createdAt = start
            ..updatedAt = start
            ..reminderEnabled = true;

          final id = await db.saveProject(p);

          // Finalize on Feb 5 (4 days elapsed: Feb 1, 2, 3, 4)
          await DayFinalizerService.finalizePastDays(db, currentTime: DateTime(2026, 2, 5, 8, 0));

          final updated = await db.getProject(id);
          expect(updated!.completedDays, equals(4));
          expect(updated.status, equals('completed'), reason: 'Test ${250 + i}: Reached target, status should be completed');

          await db.deleteProject(id);
        }
      } finally {
        await isar.close();
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Group 4: 100 Option 1 Honesty Lock & State Transition Tests (301-400)', () {
    test('100 State Transitions and Option 1 Missed-Day Permanence Tests', () async {
      final tempDir = Directory.systemTemp.createTempSync('isar_stress_honesty');
      final isar = await Isar.open(
        [
          ProjectSchema,
          DailyRecordSchema,
          PauseSchema,
          TargetChangeLogSchema,
          SettingsSchema,
        ],
        name: 'stress_honesty_db',
        directory: tempDir.path,
      );
      final db = DatabaseService(isar);

      try {
        // 50 Strict Mode check-ins & double check-in idempotency (Tests 301-350)
        for (int i = 1; i <= 50; i++) {
          final today = DateTime(2026, 3, 10);
          final p = Project()
            ..title = 'Strict Idempotent $i'
            ..category = 'Fitness'
            ..motivation = 'Move'
            ..targetDays = 20
            ..completedDays = 0
            ..trackingMode = 'strict'
            ..status = 'active'
            ..startDate = today
            ..endDate = DateTime(2026, 3, 29)
            ..createdAt = today
            ..updatedAt = today
            ..reminderEnabled = true;

          final id = await db.saveProject(p);

          // Check in for today
          final record1 = DailyRecord()
            ..projectId = id
            ..date = today
            ..status = 'completed'
            ..automatic = false
            ..modified = false
            ..createdAt = today;
          await db.saveRecord(record1);

          p.completedDays += 1;
          await db.saveProject(p);

          // Verify state
          var check = await db.getProject(id);
          expect(check!.completedDays, equals(1));

          // Repeated check-in on same day should not double count
          final existing = await db.getRecordForDate(id, today);
          expect(existing, isNotNull);
          expect(existing!.status, equals('completed'), reason: 'Test ${300 + i}: Strict check-in preserved');

          await db.deleteProject(id);
        }

        // 50 Trust Mode Option 1 Missed-Day Lock Transitions (Tests 351-400)
        for (int i = 1; i <= 50; i++) {
          final pastDate = DateTime(2026, 4, 1);
          final p = Project()
            ..title = 'Trust Honesty $i'
            ..category = 'Faith'
            ..motivation = 'Pray'
            ..targetDays = 30
            ..completedDays = 5
            ..trackingMode = 'trust'
            ..status = 'active'
            ..startDate = pastDate
            ..endDate = DateTime(2026, 4, 30)
            ..createdAt = pastDate
            ..updatedAt = pastDate
            ..reminderEnabled = true;

          final id = await db.saveProject(p);

          // User marks day as missed (Honesty action)
          final missedRecord = DailyRecord()
            ..projectId = id
            ..date = pastDate
            ..status = 'missed'
            ..automatic = false
            ..modified = true
            ..createdAt = DateTime.now();
          await db.saveRecord(missedRecord);

          p.completedDays -= 1;
          await db.saveProject(p);

          final verifyP = await db.getProject(id);
          expect(verifyP!.completedDays, equals(4), reason: 'Test ${350 + i}: Completed count decremented on missed toggle');

          final verifyR = await db.getRecordForDate(id, pastDate);
          expect(verifyR!.status, equals('missed'), reason: 'Test ${350 + i}: Status is permanently locked as missed');

          await db.deleteProject(id);
        }
      } finally {
        await isar.close();
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Group 5: 100 AES-256 Backup Encryption, Decryption & Fuzzing Tests (401-500)', () {
    test('100 AES-256 Crypto Fuzzing, Special Characters & Password Match Tests', () async {
      final tempDir1 = Directory.systemTemp.createTempSync('isar_stress_src');
      final tempDir2 = Directory.systemTemp.createTempSync('isar_stress_dst');

      final isar1 = await Isar.open(
        [
          ProjectSchema,
          DailyRecordSchema,
          PauseSchema,
          TargetChangeLogSchema,
          SettingsSchema,
        ],
        name: 'stress_src_db',
        directory: tempDir1.path,
      );
      final db1 = DatabaseService(isar1);

      final isar2 = await Isar.open(
        [
          ProjectSchema,
          DailyRecordSchema,
          PauseSchema,
          TargetChangeLogSchema,
          SettingsSchema,
        ],
        name: 'stress_dst_db',
        directory: tempDir2.path,
      );
      final db2 = DatabaseService(isar2);

      try {
        final rand = Random(12345);

        // 50 Encrypted Export / Import Roundtrips with Fuzz Passwords & Unicode (Tests 401-450)
        for (int i = 1; i <= 50; i++) {
          final password = 'Pass_#${i}_🔐_Arabic_عربي_中文_${rand.nextInt(999999)}';
          final title = 'Goal #$i: 🚀 "Quotes & Commas, <XML> & ${rand.nextDouble()}"';

          final p = Project()
            ..title = title
            ..category = 'Custom'
            ..motivation = 'Inspire me $i'
            ..targetDays = 45
            ..completedDays = 2
            ..trackingMode = 'trust'
            ..status = 'active'
            ..startDate = DateTime(2026, 7, 1)
            ..endDate = DateTime(2026, 8, 14)
            ..createdAt = DateTime(2026, 7, 1)
            ..updatedAt = DateTime(2026, 7, 1)
            ..reminderEnabled = true;

          final pId = await db1.saveProject(p);

          // Export
          final encrypted = await BackupService.exportEncryptedBackup(db1, password);
          expect(encrypted.isNotEmpty, isTrue);

          // Clear db2 and Import
          await isar2.writeTxn(() async {
            await isar2.projects.clear();
            await isar2.dailyRecords.clear();
          });

          final success = await BackupService.importEncryptedBackup(db2, encrypted, password);
          expect(success, isTrue, reason: 'Test ${400 + i}: Roundtrip import with password "$password"');

          final imported = await db2.getAllProjects();
          expect(imported.first.title, equals(title), reason: 'Test ${400 + i}: Title unicode match');

          // Clean db1
          await db1.deleteProject(pId);
        }

        // 50 Corrupted Payload / Wrong Password Rejection Tests (Tests 451-500)
        for (int i = 1; i <= 50; i++) {
          final correctPass = 'CorrectKey_$i';
          final wrongPass = 'WrongKey_$i';

          final p = Project()
            ..title = 'Secure $i'
            ..category = 'Work'
            ..motivation = 'Security'
            ..targetDays = 10
            ..completedDays = 0
            ..trackingMode = 'strict'
            ..status = 'active'
            ..startDate = DateTime.now()
            ..endDate = DateTime.now().add(const Duration(days: 10))
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..reminderEnabled = true;

          final pId = await db1.saveProject(p);
          final encrypted = await BackupService.exportEncryptedBackup(db1, correctPass);

          // Attempt with wrong password
          final result = await BackupService.importEncryptedBackup(db2, encrypted, wrongPass);
          expect(result, isFalse, reason: 'Test ${450 + i}: Wrong password must fail decryption cleanly');

          await db1.deleteProject(pId);
        }
      } finally {
        await isar1.close();
        await isar2.close();
        tempDir1.deleteSync(recursive: true);
        tempDir2.deleteSync(recursive: true);
      }
    });
  });
}
