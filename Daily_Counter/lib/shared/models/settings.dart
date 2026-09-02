import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = 1; // Fixed id to enforce singleton behavior in Isar

  late DateTime reminderTime;

  late String themeMode; // system, light, dark

  late String language;

  late int backupVersion;
}
