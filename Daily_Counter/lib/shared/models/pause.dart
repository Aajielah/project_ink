import 'package:isar/isar.dart';

part 'pause.g.dart';

@collection
class Pause {
  Id id = Isar.autoIncrement;

  @Index()
  late int projectId;

  late DateTime startDate;

  DateTime? endDate; // Null if currently paused

  String? reason;
}
