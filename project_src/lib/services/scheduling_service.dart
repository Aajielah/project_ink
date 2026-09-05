import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/schedule.dart';
import '../shared/date_utils.dart';

class SchedulingService {
  const SchedulingService();

  /// Validates schedule inputs. Returns null if valid, or an error string if invalid.
  String? validateInputs({
    required int targetWords,
    required int dailyWordTarget,
    required int durationDays,
    required RestMode restMode,
    List<int>? fixedRestWeekdays,
    required int allowedRestDays,
    DateTime? startDate,
  }) {
    if (targetWords <= 0) {
      return 'Target words must be greater than zero.';
    }
    if (dailyWordTarget <= 0) {
      return 'Daily target words must be greater than zero.';
    }
    if (durationDays <= 0) {
      return 'Project duration must be at least 1 day.';
    }

    int restDaysEstimate = 0;

    if (restMode == RestMode.fixed) {
      if (fixedRestWeekdays == null || fixedRestWeekdays.isEmpty) {
        return 'Fixed rest days must specify which days of the week are rest days.';
      }
      // Count how many rest days occur in the duration starting from actual start date
      final startWeekday = startDate?.weekday ?? 1;
      for (int i = 0; i < durationDays; i++) {
        // Monday = 1, Sunday = 7
        final day = ((startWeekday - 1 + i) % 7) + 1;
        if (fixedRestWeekdays.contains(day)) {
          restDaysEstimate++;
        }
      }
    } else if (restMode == RestMode.flexible || restMode == RestMode.adaptive) {
      if (allowedRestDays < 0) {
        return 'Rest Days cannot be negative.';
      }
      if (allowedRestDays == 0) {
        return '${restMode == RestMode.flexible ? "Flexible" : "Adaptive"} Rest Days must be at least 1.';
      }
      final writingDays = durationDays - allowedRestDays;
      if (writingDays <= 0 || writingDays * dailyWordTarget < targetWords) {
        return 'This configuration cannot complete your project. Reduce your total rest days, increase your daily target, or extend the project duration.';
      }
      restDaysEstimate = allowedRestDays;
    } else if (restMode == RestMode.sprint) {
      if (allowedRestDays != 0) {
        return 'Sprint Mode does not allow rest days.';
      }
      if (durationDays > 10) {
        return 'Sprint Mode is only available for projects lasting 10 days or fewer.';
      }
      restDaysEstimate = 0;
    }

    final writingDays = durationDays - restDaysEstimate;
    if (writingDays <= 0) {
      return 'The selected configuration has no writing days.';
    }

    final maxPossibleWords = writingDays * dailyWordTarget;
    if (maxPossibleWords < targetWords) {
      return 'Impossible schedule: at $dailyWordTarget words/day for $writingDays writing days, you can only write a maximum of $maxPossibleWords words (Target is $targetWords). Please increase the duration or daily target.';
    }

    return null;
  }

  /// Returns the weekly allocation for a given week of a project.
  int getWeeklyAllocation({
    required int totalRestDays,
    required int durationDays,
    required int week,
  }) {
    final weeks = (durationDays / 7.0).ceil();
    if (week < 1 || week > weeks) return 0;
    final base = totalRestDays ~/ weeks;
    final remainder = totalRestDays % weeks;
    return base + ((week - 1) < remainder ? 1 : 0);
  }

  /// Calculates the available rest days for a project on a given logical date.
  int getAvailableRestDays({
    required ProjectModel project,
    required List<ScheduleModel> schedules,
    required DateTime logicalToday,
  }) {
    if (project.projectType == ProjectType.ongoing) {
      return 9999;
    }
    final durationDays = getDaysDifference(project.startDate, project.expectedFinishDate) + 1;
    final currentWeek = (getDaysDifference(project.startDate, logicalToday) ~/ 7) + 1;

    final totalUsed = schedules.where((s) => s.isRestDay).length;

    if (project.restMode == RestMode.flexible) {
      int totalAllocatedUpToNow = 0;
      for (int w = 1; w <= currentWeek; w++) {
        totalAllocatedUpToNow += getWeeklyAllocation(
          totalRestDays: project.allowedRestDays,
          durationDays: durationDays,
          week: w,
        );
      }
      return max(0, totalAllocatedUpToNow - totalUsed);
    } else if (project.restMode == RestMode.adaptive) {
      final allocatedCurrentWeek = getWeeklyAllocation(
        totalRestDays: project.allowedRestDays,
        durationDays: durationDays,
        week: currentWeek,
      );
      int usedCurrentWeek = 0;
      for (final s in schedules) {
        if (s.isRestDay) {
          final diff = getDaysDifference(project.startDate, s.date);
          final w = (diff ~/ 7) + 1;
          if (w == currentWeek) {
            usedCurrentWeek++;
          }
        }
      }
      final overallRemaining = max(0, project.allowedRestDays - totalUsed);
      return max(0, min(allocatedCurrentWeek - usedCurrentWeek, overallRemaining));
    }
    return 0;
  }

  /// Generates a new schedule list for a project based on config.
  List<ScheduleModel> generateInitialSchedule({
    required String projectId,
    required DateTime startDate,
    required int targetWords,
    required int dailyWordTarget,
    required int durationDays,
    required RestMode restMode,
    required List<int> fixedRestWeekdays,
    required int allowedRestDays,
  }) {
    final List<ScheduleModel> schedules = [];
    final uuid = const Uuid();
    final cleanStartDate = DateTime(startDate.year, startDate.month, startDate.day);

    // Determine rest days for all dates
    final List<bool> restDayMap = List.filled(durationDays, false);

    if (restMode == RestMode.fixed) {
      for (int i = 0; i < durationDays; i++) {
        final date = DateTime(cleanStartDate.year, cleanStartDate.month, cleanStartDate.day + i);
        if (fixedRestWeekdays.contains(date.weekday)) {
          restDayMap[i] = true;
        }
      }
    } else if (restMode == RestMode.adaptive) {
      // Adaptive: initially no rest days are pre-assigned in calendar under new spec.
    } else {
      // Flexible: initially no rest days are pre-assigned in calendar.
      // The user marks them as rest days dynamically up to their budget.
    }

    // Calculate planned words distribution
    int remainingWords = targetWords;
    
    // First pass: count actual writing days
    int writingDaysCount = 0;
    for (int i = 0; i < durationDays; i++) {
      if (!restDayMap[i]) writingDaysCount++;
    }

    for (int i = 0; i < durationDays; i++) {
      final date = DateTime(cleanStartDate.year, cleanStartDate.month, cleanStartDate.day + i);
      final isRest = restDayMap[i];
      int planned = 0;

      if (!isRest) {
        // Standard distribution: write dailyWordTarget until we hit targetWords
        planned = min(dailyWordTarget, remainingWords);
        remainingWords -= planned;
      }

      schedules.add(ScheduleModel(
        id: uuid.v4(),
        projectId: projectId,
        date: date,
        plannedWords: planned,
        isRestDay: isRest,
        completed: false,
        automaticRestDay: false,
        locked: false,
      ));
    }

    return schedules;
  }

  /// Recalculates only remaining future schedules after plan adjustments.
  /// Historically locked logs/schedules are preserved.
  List<ScheduleModel> recalculateFutureSchedule({
    required List<ScheduleModel> existingSchedules,
    required DateTime recalculateFromDate,
    required int newDailyTarget,
    required int totalRemainingWords,
    required List<int> fixedRestWeekdays,
    required RestMode restMode,
    required int allowedRestDaysBudget,
    required int restDaysUsed,
  }) {
    final List<ScheduleModel> updatedSchedules = [];
    final uuid = const Uuid();
    final cleanFromDate = DateTime(recalculateFromDate.year, recalculateFromDate.month, recalculateFromDate.day);

    // Keep all locked and past schedules unchanged
    int wordsAllocatedInHistory = 0;
    for (final sched in existingSchedules) {
      if (sched.locked || sched.date.isBefore(cleanFromDate)) {
        updatedSchedules.add(sched);
        if (sched.completed) {
          // Words already completed in history are deducted from target
        }
      }
    }

    // Filter future schedules that are not locked
    final List<ScheduleModel> futureSchedulesToRedo = existingSchedules
        .where((s) => !s.locked && !s.date.isBefore(cleanFromDate))
        .toList();

    if (futureSchedulesToRedo.isEmpty) {
      return updatedSchedules;
    }

    final totalFutureDays = futureSchedulesToRedo.length;
    final List<bool> newRestMap = List.filled(totalFutureDays, false);

    // Distribute rest days in future schedules
    if (restMode == RestMode.fixed) {
      for (int i = 0; i < totalFutureDays; i++) {
        final date = futureSchedulesToRedo[i].date;
        if (fixedRestWeekdays.contains(date.weekday)) {
          newRestMap[i] = true;
        }
      }
    } else if (restMode == RestMode.adaptive) {
      // Adaptive: initially no rest days are pre-assigned in calendar under new spec.
    }

    // Reallocate remaining words across future writing days
    int remainingWordsToPlan = totalRemainingWords;
    for (int i = 0; i < totalFutureDays; i++) {
      final oldSched = futureSchedulesToRedo[i];
      final isRest = newRestMap[i];
      int planned = 0;

      if (!isRest) {
        planned = min(newDailyTarget, remainingWordsToPlan);
        remainingWordsToPlan -= planned;
      }

      updatedSchedules.add(ScheduleModel(
        id: oldSched.id, // keep original UUID
        projectId: oldSched.projectId,
        date: oldSched.date,
        plannedWords: planned,
        isRestDay: isRest,
        completed: false,
        automaticRestDay: false,
        locked: false,
      ));
    }

    return updatedSchedules;
  }

  /// Checks if a rest day is allowed on a given date (respects the 2-day cooldown rule).
  bool isRestDayAllowed({
    required List<ScheduleModel> schedules,
    required DateTime targetDate,
  }) {
    final cleanTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final d1 = cleanTarget.subtract(const Duration(days: 1));
    final d2 = cleanTarget.subtract(const Duration(days: 2));

    final hasRestInWindow = schedules.any((s) => s.isRestDay && (
      (s.date.year == d1.year && s.date.month == d1.month && s.date.day == d1.day) ||
      (s.date.year == d2.year && s.date.month == d2.month && s.date.day == d2.day)
    ));

    return !hasRestInWindow;
  }
}
