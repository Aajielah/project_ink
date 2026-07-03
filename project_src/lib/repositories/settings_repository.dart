import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/settings.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  SettingsModel _mapToModel(SettingsTableData data) {
    return SettingsModel(
      id: data.id,
      theme: data.theme,
      notifications: data.notifications,
      dailyQuotes: data.dailyQuotes,
      backupReminder: data.backupReminder,
      vibration: data.vibration,
    );
  }

  SettingsTableCompanion _mapToCompanion(SettingsModel model) {
    return SettingsTableCompanion(
      id: Value(model.id),
      theme: Value(model.theme),
      notifications: Value(model.notifications),
      dailyQuotes: Value(model.dailyQuotes),
      backupReminder: Value(model.backupReminder),
      vibration: Value(model.vibration),
    );
  }

  Future<SettingsModel> getSettings() async {
    final results = await _db.select(_db.settingsTable).get();
    if (results.isEmpty) {
      final defaultSettings = SettingsModel(
        id: const Uuid().v4(),
        theme: 'system',
        notifications: true,
        dailyQuotes: true,
        backupReminder: true,
        vibration: true,
      );
      await insertSettings(defaultSettings);
      return defaultSettings;
    }
    return _mapToModel(results.first);
  }

  Future<void> insertSettings(SettingsModel settings) async {
    await _db.into(_db.settingsTable).insert(_mapToCompanion(settings), mode: InsertMode.insertOrReplace);
  }

  Future<void> updateSettings(SettingsModel settings) async {
    await (_db.update(_db.settingsTable)..where((t) => t.id.equals(settings.id)))
        .write(_mapToCompanion(settings));
  }
}
