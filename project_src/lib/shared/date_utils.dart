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
    return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  }
  return DateTime(now.year, now.month, now.day);
}

/// Safely calculates difference in days between two dates, avoiding daylight saving offsets.
int getDaysDifference(DateTime start, DateTime end) {
  final utcStart = DateTime.utc(start.year, start.month, start.day);
  final utcEnd = DateTime.utc(end.year, end.month, end.day);
  return utcEnd.difference(utcStart).inDays;
}
