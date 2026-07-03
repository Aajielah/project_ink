import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/schedule.dart';

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
  }) {
    if (targetWords <= 0) return 'Target words must be greater than zero.';
    if (dailyWordTarget <= 0) return 'Daily word target must be greater than zero.';
    if (durationDays <= 0) return 'Duration must be at least 1 day.';

    // Calculate approximate number of weeks
    final weeks = (durationDays / 7.0).ceil();
    int restDaysEstimate = 0;

    if (restMode == RestMode.fixed) {
      if (fixedRestWeekdays == null || fixedRestWeekdays.isEmpty) {
        return 'Fixed rest days must specify which days of the week are rest days.';
      }
      // Count how many rest days occur in the duration
      for (int i = 0; i < durationDays; i++) {
        // Monday = 1, Sunday = 7
        final day = (i % 7) + 1;
        if (fixedRestWeekdays.contains(day)) {
          restDaysEstimate++;
        }
      }
    } else {
      // Flexible or Random rest days budget
      restDaysEstimate = allowedRestDays * weeks;
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
        final date = cleanStartDate.add(Duration(days: i));
        if (fixedRestWeekdays.contains(date.weekday)) {
          restDayMap[i] = true;
        }
      }
    } else if (restMode == RestMode.random) {
      // Assign allowedRestDays randomly per 7-day week blocks
      final random = Random();
      for (int weekStart = 0; weekStart < durationDays; weekStart += 7) {
        final weekEnd = min(weekStart + 7, durationDays);
        final weekLength = weekEnd - weekStart;
        final restCount = min(allowedRestDays, weekLength);

        // Get indices of days in this week
        final List<int> indices = List.generate(weekLength, (index) => weekStart + index);
        indices.shuffle(random);

        // Select the first restCount indices as rest days
        for (int r = 0; r < restCount; r++) {
          restDayMap[indices[r]] = true;
        }
      }
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
      final date = cleanStartDate.add(Duration(days: i));
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
    } else if (restMode == RestMode.random) {
      // Calculate remaining budget
      final weeksLeft = (totalFutureDays / 7.0).ceil();
      final remainingRestBudget = max(0, allowedRestDaysBudget - restDaysUsed);
      final restPerWeek = min(remainingRestBudget, allowedRestDaysBudget); // cap at weekly limit

      final random = Random();
      for (int weekStart = 0; weekStart < totalFutureDays; weekStart += 7) {
        final weekEnd = min(weekStart + 7, totalFutureDays);
        final weekLength = weekEnd - weekStart;
        final restCount = min(restPerWeek, weekLength);

        final List<int> indices = List.generate(weekLength, (index) => weekStart + index);
        indices.shuffle(random);

        for (int r = 0; r < restCount; r++) {
          newRestMap[indices[r]] = true;
        }
      }
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
}
