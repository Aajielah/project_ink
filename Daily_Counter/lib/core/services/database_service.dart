import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/project.dart';
import '../../shared/models/daily_record.dart';
import '../../shared/models/pause.dart';
import '../../shared/models/target_change_log.dart';
import '../../shared/models/settings.dart';

class DatabaseService {
  final Isar isar;

  DatabaseService(this.isar);

  static Future<DatabaseService> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        ProjectSchema,
        DailyRecordSchema,
        PauseSchema,
        TargetChangeLogSchema,
        SettingsSchema,
      ],
      directory: dir.path,
    );

    final service = DatabaseService(isar);
    await service.getSettings(); // Ensures default settings row exists

    return service;
  }

  // --- Project Operations ---

  Future<List<Project>> getAllProjects() async {
    return isar.projects.where().findAll();
  }

  Future<Project?> getProject(int id) async {
    return isar.projects.get(id);
  }

  Future<int> saveProject(Project project) async {
    project.updatedAt = DateTime.now();
    return isar.writeTxn(() async {
      return await isar.projects.put(project);
    });
  }

  Future<bool> deleteProject(int id) async {
    return isar.writeTxn(() async {
      await isar.dailyRecords.filter().projectIdEqualTo(id).deleteAll();
      await isar.pauses.filter().projectIdEqualTo(id).deleteAll();
      await isar.targetChangeLogs.filter().projectIdEqualTo(id).deleteAll();
      return await isar.projects.delete(id);
    });
  }

  Future<void> clearProjectRecords(int id) async {
    await isar.writeTxn(() async {
      await isar.dailyRecords.filter().projectIdEqualTo(id).deleteAll();
      await isar.pauses.filter().projectIdEqualTo(id).deleteAll();
    });
  }

  // --- DailyRecord Operations ---

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<List<DailyRecord>> getRecordsForProject(int projectId) async {
    return isar.dailyRecords.filter().projectIdEqualTo(projectId).findAll();
  }

  Future<DailyRecord?> getRecordForDate(int projectId, DateTime date) async {
    final normalized = _normalizeDate(date);
    return isar.dailyRecords
        .filter()
        .projectIdEqualTo(projectId)
        .dateEqualTo(normalized)
        .findFirst();
  }

  Future<int> saveRecord(DailyRecord record) async {
    record.date = _normalizeDate(record.date);
    return isar.writeTxn(() async {
      return await isar.dailyRecords.put(record);
    });
  }

  Future<void> saveRecords(List<DailyRecord> records) async {
    for (var r in records) {
      r.date = _normalizeDate(r.date);
    }
    await isar.writeTxn(() async {
      await isar.dailyRecords.putAll(records);
    });
  }

  // --- Pause Operations ---

  Future<List<Pause>> getPausesForProject(int projectId) async {
    return isar.pauses.filter().projectIdEqualTo(projectId).findAll();
  }

  Future<int> savePause(Pause pause) async {
    return isar.writeTxn(() async {
      return await isar.pauses.put(pause);
    });
  }

  // --- TargetChangeLog Operations ---

  Future<List<TargetChangeLog>> getLogsForProject(int projectId) async {
    return isar.targetChangeLogs.filter().projectIdEqualTo(projectId).findAll();
  }

  Future<int> saveTargetChangeLog(TargetChangeLog log) async {
    return isar.writeTxn(() async {
      return await isar.targetChangeLogs.put(log);
    });
  }

  // --- Settings Operations ---

  Future<Settings> getSettings() async {
    final settings = await isar.settings.get(1);
    if (settings != null) return settings;

    // Fallback self-healing: automatically create and return default settings
    final defaultSettings = Settings()
      ..id = 1
      ..reminderTime = DateTime(2026, 1, 1, 20, 0)
      ..themeMode = 'system'
      ..language = 'en'
      ..backupVersion = 1;

    await isar.writeTxn(() async {
      await isar.settings.put(defaultSettings);
    });
    return defaultSettings;
  }

  Future<void> saveSettings(Settings settings) async {
    settings.id = 1;
    await isar.writeTxn(() async {
      await isar.settings.put(settings);
    });
  }
}
