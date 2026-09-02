import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../../shared/models/project.dart';
import '../../shared/models/daily_record.dart';
import '../../shared/models/pause.dart';
import '../../shared/models/target_change_log.dart';
import '../../shared/models/settings.dart';
import 'database_service.dart';

class BackupService {
  static enc.Key _deriveKey(String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  static enc.IV _deriveIV(String password) {
    final ivBytes = md5.convert(utf8.encode('${password}_daily_counter_iv')).bytes;
    return enc.IV(Uint8List.fromList(ivBytes));
  }

  /// Exports all database collections into an AES-256 encrypted base64 payload.
  static Future<String> exportEncryptedBackup(DatabaseService db, String password) async {
    final projects = await db.getAllProjects();
    final settings = await db.getSettings();

    final List<Map<String, dynamic>> projectsData = [];
    final List<Map<String, dynamic>> recordsData = [];
    final List<Map<String, dynamic>> pausesData = [];
    final List<Map<String, dynamic>> logsData = [];

    for (var p in projects) {
      projectsData.add({
        'id': p.id,
        'title': p.title,
        'category': p.category,
        'motivation': p.motivation,
        'targetDays': p.targetDays,
        'completedDays': p.completedDays,
        'trackingMode': p.trackingMode,
        'status': p.status,
        'startDate': p.startDate.toIso8601String(),
        'endDate': p.endDate.toIso8601String(),
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'reminderEnabled': p.reminderEnabled,
      });

      final records = await db.getRecordsForProject(p.id);
      for (var r in records) {
        recordsData.add({
          'projectId': r.projectId,
          'date': r.date.toIso8601String(),
          'status': r.status,
          'automatic': r.automatic,
          'modified': r.modified,
          'createdAt': r.createdAt.toIso8601String(),
        });
      }

      final pauses = await db.getPausesForProject(p.id);
      for (var pa in pauses) {
        pausesData.add({
          'projectId': pa.projectId,
          'startDate': pa.startDate.toIso8601String(),
          'endDate': pa.endDate?.toIso8601String(),
          'reason': pa.reason,
        });
      }

      final logs = await db.getLogsForProject(p.id);
      for (var l in logs) {
        logsData.add({
          'projectId': l.projectId,
          'oldTarget': l.oldTarget,
          'newTarget': l.newTarget,
          'dateChanged': l.dateChanged.toIso8601String(),
        });
      }
    }

    final backupPayload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'reminderTime': settings.reminderTime.toIso8601String(),
        'themeMode': settings.themeMode,
        'language': settings.language,
        'backupVersion': settings.backupVersion,
      },
      'projects': projectsData,
      'dailyRecords': recordsData,
      'pauses': pausesData,
      'targetChangeLogs': logsData,
    };

    final rawJson = jsonEncode(backupPayload);
    final key = _deriveKey(password);
    final iv = _deriveIV(password);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(rawJson, iv: iv);

    return encrypted.base64;
  }

  /// Decrypts and restores an AES-256 encrypted backup payload into the database.
  static Future<bool> importEncryptedBackup(
    DatabaseService db,
    String encryptedPayload,
    String password,
  ) async {
    try {
      final key = _deriveKey(password);
      final iv = _deriveIV(password);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted.fromBase64(encryptedPayload.trim()), iv: iv);

      final Map<String, dynamic> data = jsonDecode(decrypted);
      final List projectsJson = data['projects'] ?? [];
      final List recordsJson = data['dailyRecords'] ?? [];
      final List pausesJson = data['pauses'] ?? [];
      final List logsJson = data['targetChangeLogs'] ?? [];

      for (var pMap in projectsJson) {
        final project = Project()
          ..title = pMap['title']
          ..category = pMap['category']
          ..motivation = pMap['motivation']
          ..targetDays = pMap['targetDays']
          ..completedDays = pMap['completedDays']
          ..trackingMode = pMap['trackingMode']
          ..status = pMap['status']
          ..startDate = DateTime.parse(pMap['startDate'])
          ..endDate = DateTime.parse(pMap['endDate'])
          ..createdAt = DateTime.parse(pMap['createdAt'])
          ..updatedAt = DateTime.parse(pMap['updatedAt'])
          ..reminderEnabled = pMap['reminderEnabled'] ?? true;

        final newId = await db.saveProject(project);

        // Restore matching records
        final oldId = pMap['id'];
        for (var rMap in recordsJson) {
          if (rMap['projectId'] == oldId) {
            final record = DailyRecord()
              ..projectId = newId
              ..date = DateTime.parse(rMap['date'])
              ..status = rMap['status']
              ..automatic = rMap['automatic'] ?? false
              ..modified = rMap['modified'] ?? false
              ..createdAt = DateTime.parse(rMap['createdAt']);
            await db.saveRecord(record);
          }
        }

        // Restore matching pauses
        for (var paMap in pausesJson) {
          if (paMap['projectId'] == oldId) {
            final pause = Pause()
              ..projectId = newId
              ..startDate = DateTime.parse(paMap['startDate'])
              ..endDate = paMap['endDate'] != null ? DateTime.parse(paMap['endDate']) : null
              ..reason = paMap['reason'];
            await db.savePause(pause);
          }
        }

        // Restore matching target logs
        for (var lMap in logsJson) {
          if (lMap['projectId'] == oldId) {
            final log = TargetChangeLog()
              ..projectId = newId
              ..oldTarget = lMap['oldTarget']
              ..newTarget = lMap['newTarget']
              ..dateChanged = DateTime.parse(lMap['dateChanged']);
            await db.saveTargetChangeLog(log);
          }
        }
      }

      // Restore settings
      if (data['settings'] != null) {
        final sMap = data['settings'];
        final settings = Settings()
          ..id = 1
          ..reminderTime = DateTime.parse(sMap['reminderTime'])
          ..themeMode = sMap['themeMode'] ?? 'system'
          ..language = sMap['language'] ?? 'en'
          ..backupVersion = sMap['backupVersion'] ?? 1;
        await db.saveSettings(settings);
      }

      return true;
    } catch (_) {
      return false; // Decryption failed (e.g. wrong password or corrupt payload)
    }
  }
}
