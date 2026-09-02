import 'package:isar/isar.dart';

part 'project.g.dart';

@collection
class Project {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String title;

  late String category;
  late String motivation;
  late int targetDays;
  late int completedDays;
  late String trackingMode; // strict, trust
  late String status; // upcoming, active, paused, completed, archived
  late DateTime startDate;
  late DateTime endDate;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool reminderEnabled;
}
