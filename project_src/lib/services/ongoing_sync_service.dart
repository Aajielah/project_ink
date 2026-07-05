import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../shared/date_utils.dart';

import '../models/project.dart';
import '../models/schedule.dart';
import '../models/daily_log.dart';
import '../shared/providers.dart';

final ongoingSyncServiceProvider = Provider((ref) => OngoingSyncService(ref));

class OngoingSyncService {
  final Ref _ref;

  const OngoingSyncService(this._ref);

  /// Incrementally syncs ongoing projects daily.
  /// 1. Finds all past unlocked schedule days and locks them as automatic Rest Days.
  /// 2. Scans for any calendar gaps between the latest schedule date and today, generating rest days.
  /// 3. Safely prepares today's target habit task.
  Future<void> syncOngoingSchedules(List<ProjectModel> activeProjects) async {
    final schedRepo = _ref.read(scheduleRepositoryProvider);
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final uuid = const Uuid();

    for (final project in activeProjects) {
      if (project.projectType != ProjectType.ongoing) continue;

      final schedules = await schedRepo.getSchedulesForProject(project.id);

      // Case 1: Brand new ongoing project, check and fill dates from startDate up to today
      if (schedules.isEmpty) {
        final cleanStart = DateTime(project.startDate.year, project.startDate.month, project.startDate.day);
        if (cleanToday.isAtSameMomentAs(cleanStart) || cleanToday.isAfter(cleanStart)) {
          final List<ScheduleModel> initialTasks = [];
          var tempDate = cleanStart;
          while (tempDate.isBefore(cleanToday)) {
            initialTasks.add(ScheduleModel(
              id: uuid.v4(),
              projectId: project.id,
              date: tempDate,
              plannedWords: 0,
              isRestDay: true,
              automaticRestDay: true,
              completed: false,
              locked: true,
            ));
            tempDate = tempDate.add(const Duration(days: 1));
          }
          // Add today's habit task
          initialTasks.add(ScheduleModel(
            id: uuid.v4(),
            projectId: project.id,
            date: cleanToday,
            plannedWords: project.dailyWordTarget,
            isRestDay: false,
            completed: false,
            automaticRestDay: false,
            locked: false,
          ));
          await schedRepo.insertSchedules(initialTasks);
        }
        continue;
      }

      // Case 2: Finalize past schedules (convert to automatic Rest Days if not completed)
      final logRepo = _ref.read(dailyLogRepositoryProvider);
      final List<ScheduleModel> toUpdate = [];
      for (final s in schedules) {
        if (s.date.isBefore(cleanToday) && !s.completed && (!s.isRestDay || s.plannedWords > 0)) {
          toUpdate.add(s.copyWith(
            plannedWords: 0,
            isRestDay: true,
            automaticRestDay: true,
            completed: false,
            locked: true,
          ));
          
          final existingLog = await logRepo.getLogForDate(project.id, s.date);
          if (existingLog != null) {
            await logRepo.insertLog(existingLog.copyWith(
              plannedWords: 0,
              backlogCreated: 0,
              completed: false,
            ));
          }
        }
      }

      // Case 3: Check for calendar gaps between the latest generated date and today
      final latestDate = schedules.fold<DateTime>(
        schedules.first.date,
        (latest, s) => s.date.isAfter(latest) ? s.date : latest,
      );
      final List<ScheduleModel> toInsert = [];

      if (latestDate.isBefore(cleanToday)) {
        var tempDate = latestDate.add(const Duration(days: 1));
        while (tempDate.isBefore(cleanToday)) {
          toInsert.add(ScheduleModel(
            id: uuid.v4(),
            projectId: project.id,
            date: tempDate,
            plannedWords: 0,
            isRestDay: true,
            automaticRestDay: true,
            completed: false,
            locked: true,
          ));
          tempDate = tempDate.add(const Duration(days: 1));
        }
        toInsert.add(ScheduleModel(
          id: uuid.v4(),
          projectId: project.id,
          date: cleanToday,
          plannedWords: project.dailyWordTarget,
          isRestDay: false,
          completed: false,
          automaticRestDay: false,
          locked: false,
        ));
      } else {
        // Safety check: ensure today has a habit task if not yet present
        final hasToday = schedules.any((s) => s.date.isAtSameMomentAs(cleanToday));
        if (!hasToday) {
          toInsert.add(ScheduleModel(
            id: uuid.v4(),
            projectId: project.id,
            date: cleanToday,
            plannedWords: project.dailyWordTarget,
            isRestDay: false,
            completed: false,
            automaticRestDay: false,
            locked: false,
          ));
        }
      }

      if (toUpdate.isNotEmpty) {
        await schedRepo.insertSchedules(toUpdate);
      }
      if (toInsert.isNotEmpty) {
        await schedRepo.insertSchedules(toInsert);
      }
    }
  }

  /// Incremental rollover for Fixed Goal projects.
  /// Scans for past uncompleted writing days and moves their remaining targets to backlog.
  Future<void> syncFixedGoalBacklogs(List<ProjectModel> activeProjects) async {
    final schedRepo = _ref.read(scheduleRepositoryProvider);
    final logRepo = _ref.read(dailyLogRepositoryProvider);
    final projRepo = _ref.read(projectRepositoryProvider);
    
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final uuid = const Uuid();

    for (final project in activeProjects) {
      if (project.projectType == ProjectType.ongoing) continue;

      List<ScheduleModel> currentSchedules = await schedRepo.getSchedulesForProject(project.id);
      
      // Sort past writing schedules chronologically
      final pastWritingSchedules = currentSchedules
          .where((s) => s.date.isBefore(cleanToday) && !s.isRestDay && !s.completed)
          .toList();
      pastWritingSchedules.sort((a, b) => a.date.compareTo(b.date));

      int currentRemainingRestDays = project.remainingRestDays;
      bool projectModified = false;
      List<ScheduleModel> schedulesToUpdateInDb = [];

      for (final s in pastWritingSchedules) {
        final existingLog = await logRepo.getLogForDate(project.id, s.date);
        final actual = existingLog?.actualWords ?? 0;

        if (actual == 0) {
          // Check if eligible for automatic rest day conversion
          final isFlexOrRandom = project.restMode == RestMode.flexible || project.restMode == RestMode.random;
          
          bool hasRest = false;
          if (isFlexOrRandom) {
            if (project.restMode == RestMode.flexible) {
              hasRest = getAvailableFlexibleRestDays(
                project: project,
                schedules: currentSchedules,
                logicalToday: s.date,
              ) > 0;
            } else if (project.restMode == RestMode.random) {
              final weekStart = getProjectWeekStart(project.startDate, s.date);
              final weekEnd = getProjectWeekEnd(project.startDate, s.date);
              final usedInWeek = currentSchedules.where((x) =>
                x.isRestDay &&
                (x.date.isAtSameMomentAs(weekStart) || x.date.isAfter(weekStart)) &&
                (x.date.isAtSameMomentAs(weekEnd) || x.date.isBefore(weekEnd))
              ).length;
              hasRest = usedInWeek < project.allowedRestDays;
            }
          }

          if (hasRest) {
            // 1. Mark schedule as Rest Day, planned words = 0, lock it
            final updatedS = s.copyWith(
              isRestDay: true,
              plannedWords: 0,
              locked: true,
              completed: false,
            );
            
            // Update in-memory schedules list
            currentSchedules = currentSchedules.map((x) => x.id == s.id ? updatedS : x).toList();
            schedulesToUpdateInDb.add(updatedS);

            // 2. Create/Update Daily Log so history reflects 0 planned words and no backlog
            if (existingLog != null) {
              await logRepo.insertLog(existingLog.copyWith(
                plannedWords: 0,
                backlogCreated: 0,
                completed: false,
              ));
            } else {
              await logRepo.insertLog(DailyLogModel(
                id: uuid.v4(),
                projectId: project.id,
                scheduleId: s.id,
                date: s.date,
                plannedWords: 0,
                actualWords: 0,
                carryForwardWords: 0,
                backlogCreated: 0,
                completed: false,
                loggedAt: s.date,
              ));
            }

            // 3. Deduct one available rest day
            if (project.restMode != RestMode.flexible) {
              currentRemainingRestDays--;
            }
            projectModified = true;

            // 4. Redistribute today's planned words (which was s.plannedWords) starting from tomorrow
            final tomorrow = s.date.add(const Duration(days: 1));
            
            // Calculate total future planned words starting from tomorrow (plus the words we just skipped)
            final futureSchedules = currentSchedules
                .where((x) => !x.locked && (x.date.isAfter(s.date) || x.date.isAtSameMomentAs(tomorrow)))
                .toList();
            final totalFuturePlannedWords = futureSchedules.fold<int>(0, (sum, x) => sum + x.plannedWords) + s.plannedWords;

            final restDaysUsed = currentSchedules.where((x) => (x.isRestDay || x.automaticRestDay) && (x.locked || x.date.isBefore(tomorrow))).length;

            final recalculated = _ref.read(schedulingServiceProvider).recalculateFutureSchedule(
              existingSchedules: currentSchedules,
              recalculateFromDate: tomorrow,
              newDailyTarget: project.dailyWordTarget,
              totalRemainingWords: totalFuturePlannedWords,
              fixedRestWeekdays: const [],
              restMode: project.restMode,
              allowedRestDaysBudget: project.allowedRestDays,
              restDaysUsed: restDaysUsed,
            );

            // Update in-memory list and queue updates for DB
            currentSchedules = recalculated;
            for (final r in recalculated) {
              if (!r.locked) {
                schedulesToUpdateInDb.add(r);
              }
            }
            continue; // Skip normal backlog creation since this day is resolved!
          }
        }

        // Normal backlog creation if no rest days remain or not eligible
        final target = s.plannedWords;
        if (target > 0) {
          final backlogCreated = target - actual;
          if (backlogCreated > 0) {
            if (existingLog != null) {
              await logRepo.insertLog(existingLog.copyWith(
                backlogCreated: backlogCreated,
              ));
            } else {
              await logRepo.insertLog(DailyLogModel(
                id: uuid.v4(),
                projectId: project.id,
                scheduleId: s.id,
                date: s.date,
                plannedWords: s.plannedWords,
                actualWords: 0,
                carryForwardWords: 0,
                backlogCreated: backlogCreated,
                completed: false,
                loggedAt: s.date,
              ));
            }
          }
        }
      }

      // Save all schedules to DB
      if (schedulesToUpdateInDb.isNotEmpty) {
        // De-duplicate schedules to update (only save the latest state for each id)
        final Map<String, ScheduleModel> uniqueUpdates = {};
        for (final s in schedulesToUpdateInDb) {
          uniqueUpdates[s.id] = s;
        }
        for (final s in uniqueUpdates.values) {
          await schedRepo.updateSchedule(s);
        }
      }

      // Update project backlog count and remaining rest days
      int calculatedBacklog = 0;
      final logs = await logRepo.getLogsForProject(project.id);
      for (final l in logs) {
        if (l.backlogCreated > 0) {
          calculatedBacklog += l.backlogCreated;
        }
      }

      if (project.backlogWords != calculatedBacklog || projectModified) {
        final updatedProject = project.copyWith(
          backlogWords: calculatedBacklog,
          remainingRestDays: currentRemainingRestDays,
          updatedAt: DateTime.now(),
        );
        await projRepo.updateProject(updatedProject);
      }
    }
  }
}
