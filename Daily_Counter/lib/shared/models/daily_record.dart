import 'package:isar/isar.dart';

part 'daily_record.g.dart';

@collection
class DailyRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late int projectId;

  @Index()
  late DateTime date; // Normalized to midnight local time

  late String status; // pending, completed, missed

  late bool automatic; // True if auto-completed by system (Trust Mode)

  late bool modified; // True if manually corrected by the user

  late DateTime createdAt;
}
