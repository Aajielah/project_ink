import '../utils/duration_utils.dart';
import '../../shared/models/daily_record.dart';
import '../../shared/models/pause.dart';
import 'database_service.dart';

class DayFinalizerService {
  /// Returns the active logical tracking date accounting for the 5:00 AM grace period.
  /// If current time is between 00:00 and 04:59 AM, the user is still in the previous day's grace period.
  static DateTime getLogicalTrackingDate(DateTime currentTime) {
    final normToday = DurationUtils.normalizeDate(currentTime);
    if (currentTime.hour < 5) {
      return normToday.subtract(const Duration(days: 1));
    }
    return normToday;
  }

  /// Checks if a date falls within any pause intervals for a project.
  static bool isDateInPause(DateTime date, List<Pause> pauses) {
    final norm = DurationUtils.normalizeDate(date);
    for (var p in pauses) {
      final start = DurationUtils.normalizeDate(p.startDate);
      final end = p.endDate != null ? DurationUtils.normalizeDate(p.endDate!) : null;
      if (end == null) {
        if (norm.isAtSameMomentAs(start) || norm.isAfter(start)) return true;
      } else {
        if ((norm.isAtSameMomentAs(start) || norm.isAfter(start)) &&
            (norm.isAtSameMomentAs(end) || norm.isBefore(end))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Finalizes all past days up to the logical yesterday for active projects.
  /// - Respects active and historical pause intervals (skips paused days).
  /// - In Strict Mode: unmarked past days are finalized as 'missed' (automatic: true).
  /// - In Trust Mode: unmarked past days are finalized as 'completed' (automatic: true) and increment completedDays.
  /// - Completes projects that reach their target.
  static Future<int> finalizePastDays(DatabaseService db, {DateTime? currentTime}) async {
    final now = currentTime ?? DateTime.now();
    final logicalToday = getLogicalTrackingDate(now);
    final projects = await db.getAllProjects();
    int processedDaysCount = 0;

    for (var project in projects) {
      if (project.status != 'active') continue;

      final normStart = DurationUtils.normalizeDate(project.startDate);
      if (logicalToday.isBefore(normStart)) continue;

      final pastCutoff = logicalToday.subtract(const Duration(days: 1));
      if (pastCutoff.isBefore(normStart)) continue;

      final pauses = await db.getPausesForProject(project.id);
      final totalDaysToEvaluate = pastCutoff.difference(normStart).inDays + 1;
      bool projectUpdated = false;

      for (int i = 0; i < totalDaysToEvaluate; i++) {
        final evaluateDate = normStart.add(Duration(days: i));

        // Skip days that were on pause
        if (isDateInPause(evaluateDate, pauses)) continue;

        final existingRecord = await db.getRecordForDate(project.id, evaluateDate);

        if (existingRecord == null) {
          if (project.trackingMode == 'strict') {
            final missedRecord = DailyRecord()
              ..projectId = project.id
              ..date = evaluateDate
              ..status = 'missed'
              ..automatic = true
              ..modified = false
              ..createdAt = now;
            await db.saveRecord(missedRecord);
            processedDaysCount++;
          } else if (project.trackingMode == 'trust') {
            final completedRecord = DailyRecord()
              ..projectId = project.id
              ..date = evaluateDate
              ..status = 'completed'
              ..automatic = true
              ..modified = false
              ..createdAt = now;
            await db.saveRecord(completedRecord);
            project.completedDays += 1;
            projectUpdated = true;
            processedDaysCount++;
          }
        }
      }

      // Check if project has reached its target
      if (project.completedDays >= project.targetDays) {
        project.status = 'completed';
        projectUpdated = true;
      }

      if (projectUpdated) {
        await db.saveProject(project);
      }
    }

    return processedDaysCount;
  }
}
