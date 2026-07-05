import 'dart:math';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/schedule.dart';

/// Calculates today's logical date based on the 5-hour grace period.
/// Between 12:00 AM and 5:00 AM, the logical date is yesterday.
DateTime getLogicalToday() {
  final now = DateTime.now();
  if (now.hour < 5) {
    return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  }
  return DateTime(now.year, now.month, now.day);
}

/// Distributes total allowed rest days as evenly as possible across project weeks.
int getFlexibleAllocationForWeek({
  required int allowedRestDays,
  required int durationDays,
  required int weekIndex,
}) {
  final totalWeeks = (durationDays / 7.0).ceil();
  if (totalWeeks <= 0) return 0;
  final base = allowedRestDays ~/ totalWeeks;
  final remainder = allowedRestDays % totalWeeks;
  return base + (weekIndex <= remainder ? 1 : 0);
}

/// Sums the weekly allocations from week 1 up to targetWeek.
int getFlexibleAllocatedUpToWeek({
  required int allowedRestDays,
  required int durationDays,
  required int targetWeek,
}) {
  int total = 0;
  for (int w = 1; w <= targetWeek; w++) {
    total += getFlexibleAllocationForWeek(
      allowedRestDays: allowedRestDays,
      durationDays: durationDays,
      weekIndex: w,
    );
  }
  return total;
}

/// Calculates the remaining available Flexible Rest Days for the current logical week,
/// including carried-over unused rest days from previous weeks.
int getAvailableFlexibleRestDays({
  required ProjectModel project,
  required List<ScheduleModel> schedules,
  required DateTime logicalToday,
}) {
  if (project.startDate == null || project.expectedFinishDate == null) return 0;
  final durationDays = project.expectedFinishDate.difference(project.startDate).inDays + 1;
  if (durationDays <= 0) return 0;

  final cleanStart = DateTime(project.startDate.year, project.startDate.month, project.startDate.day);
  final cleanToday = DateTime(logicalToday.year, logicalToday.month, logicalToday.day);

  final diffDays = cleanToday.difference(cleanStart).inDays;
  final currentWeekIndex = max(1, (diffDays ~/ 7) + 1);

  final totalWeeks = (durationDays / 7.0).ceil();
  final targetWeek = min<int>(currentWeekIndex, totalWeeks);

  final totalAllocatedUpToNow = getFlexibleAllocatedUpToWeek(
    allowedRestDays: project.allowedRestDays,
    durationDays: durationDays,
    targetWeek: targetWeek,
  );

  final totalConsumed = schedules.where((s) =>
    s.isRestDay &&
    (s.locked || s.date.isBefore(cleanToday) || s.date.isAtSameMomentAs(cleanToday))
  ).length;

  return max(0, totalAllocatedUpToNow - totalConsumed);
}

/// Calculates the start date of the project week containing the given date.
DateTime getProjectWeekStart(DateTime projectStartDate, DateTime date) {
  final cleanStart = DateTime(projectStartDate.year, projectStartDate.month, projectStartDate.day);
  final cleanDate = DateTime(date.year, date.month, date.day);
  final diffDays = cleanDate.difference(cleanStart).inDays;
  final weekIndex = diffDays ~/ 7;
  return cleanStart.add(Duration(days: weekIndex * 7));
}

/// Calculates the end date (inclusive) of the project week containing the given date.
DateTime getProjectWeekEnd(DateTime projectStartDate, DateTime date) {
  final weekStart = getProjectWeekStart(projectStartDate, date);
  return weekStart.add(const Duration(days: 6));
}
