import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/schedule.dart';

/// Calculates today's logical date based on the 5-hour grace period.
/// Between 12:00 AM and 5:00 AM, the logical date is yesterday.
DateTime getLogicalToday() {
  final now = DateTime.now();
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return DateTime(now.year, now.month, now.day);
  }
  if (now.hour < 5) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return DateTime(now.year, now.month, now.day);
}

/// Calculates today's logical date for a specific project based on completion status.
/// During the grace period (12:00 AM - 5:00 AM), if yesterday's schedule exists,
/// is a writing day, and is not completed, we keep it as yesterday's date.
/// Otherwise, it immediately rolls over to calendar today.
DateTime getLogicalTodayForProject({
  required ProjectModel project,
  required List<ScheduleModel> schedules,
}) {
  final now = DateTime.now();
  final calendarToday = DateTime(now.year, now.month, now.day);
  
  // Active time-freeze check (expires in 24 hours)
  if (project.frozenDate != null && project.freezeActivatedAt != null) {
    final elapsed = now.difference(project.freezeActivatedAt!);
    if (elapsed < const Duration(hours: 24)) {
      final cleanFrozen = DateTime(project.frozenDate!.year, project.frozenDate!.month, project.frozenDate!.day);
      ScheduleModel? frozenSched;
      for (final s in schedules) {
        if (s.projectId == project.id &&
            s.date.year == cleanFrozen.year &&
            s.date.month == cleanFrozen.month &&
            s.date.day == cleanFrozen.day) {
          frozenSched = s;
          break;
        }
      }
      if (frozenSched != null && !frozenSched.completed) {
        return cleanFrozen;
      }
    }
  }

  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return calendarToday;
  }
  if (now.hour >= 5) {
    return calendarToday;
  }
  final yesterday = DateTime(calendarToday.year, calendarToday.month, calendarToday.day - 1);
  ScheduleModel? yesterdaySchedule;
  for (final s in schedules) {
    if (s.projectId == project.id &&
        s.date.year == yesterday.year &&
        s.date.month == yesterday.month &&
        s.date.day == yesterday.day) {
      yesterdaySchedule = s;
      break;
    }
  }
  if (yesterdaySchedule != null &&
      !yesterdaySchedule.isRestDay &&
      !yesterdaySchedule.automaticRestDay &&
      !yesterdaySchedule.completed) {
    return yesterday;
  }
  return calendarToday;
}

/// Safely calculates difference in days between two dates, avoiding daylight saving offsets.
int getDaysDifference(DateTime start, DateTime end) {
  final utcStart = DateTime.utc(start.year, start.month, start.day);
  final utcEnd = DateTime.utc(end.year, end.month, end.day);
  return utcEnd.difference(utcStart).inDays;
}

/// Safely adds calendar days on midnight dates without daylight saving duration shifts.
DateTime addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Safely subtracts calendar days on midnight dates without daylight saving duration shifts.
DateTime subtractCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day - days);
}
