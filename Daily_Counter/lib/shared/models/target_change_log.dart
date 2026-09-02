import 'package:isar/isar.dart';

part 'target_change_log.g.dart';

@collection
class TargetChangeLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int projectId;

  late int oldTarget;

  late int newTarget;

  late DateTime dateChanged;
}
