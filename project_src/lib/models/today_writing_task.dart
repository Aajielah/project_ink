import 'project.dart';
import 'schedule.dart';
import 'daily_log.dart';

class TodayWritingTask {
  final ProjectModel project;
  final ScheduleModel schedule;
  final DailyLogModel? log;
  final DateTime? lastSuccessfulLogDate;

  const TodayWritingTask({
    required this.project,
    required this.schedule,
    this.log,
    this.lastSuccessfulLogDate,
  });
}
