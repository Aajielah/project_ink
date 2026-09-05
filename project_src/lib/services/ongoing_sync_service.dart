import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/date_utils.dart';

import '../models/project.dart';
import '../models/schedule.dart';
import '../models/daily_log.dart';
import '../shared/providers.dart';

import '../repositories/schedule_repository.dart';
import '../repositories/daily_log_repository.dart';

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
    final projRepo = _ref.read(projectRepositoryProvider);
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final uuid = const Uuid();

    // Check for monthly Streak Shields replenishment
    try {
      final now = DateTime.now();
      final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      final prefs = await SharedPreferences.getInstance();
      final lastReplenish = prefs.getString('last_streak_shield_replenish_month') ?? '';
      if (lastReplenish != currentMonthStr) {
        final settingsRepo = _ref.read(settingsRepositoryProvider);
        var settings = await settingsRepo.getSettings();
        if (settings.streakShields < 2) {
          settings = settings.copyWith(streakShields: 2);
          await settingsRepo.updateSettings(settings);
        }
        await prefs.setString('last_streak_shield_replenish_month', currentMonthStr);
      }
    } catch (_) {}

    for (final proj in activeProjects) {
      if (proj.projectType != ProjectType.ongoing) continue;
      var project = proj;

      // Check for active/expired Streak Shield freeze
      bool hasActiveFreeze = false;
      if (project.frozenDate != null && project.freezeActivatedAt != null) {
        final elapsed = DateTime.now().difference(project.freezeActivatedAt!);
        if (elapsed < const Duration(hours: 24)) {
          hasActiveFreeze = true;
        } else {
          final frozenDate = project.frozenDate!;
          project = project.copyWith(
            projectStreak: 0,
            clearFreeze: true,
          );
          await projRepo.updateProject(project);

          // Clear isShielded on the expired schedule
          final expiredSched = await schedRepo.getScheduleForDate(project.id, frozenDate);
          if (expiredSched != null && expiredSched.isShielded) {
            await schedRepo.updateSchedule(expiredSched.copyWith(isShielded: false, locked: false));
          }
        }
      }
      if (hasActiveFreeze) continue;

      final schedules = await schedRepo.getSchedulesForProject(project.id);

      // Case 1: Brand new ongoing project, check and fill dates from startDate up to Sunday of current week
      if (schedules.isEmpty) {
        final cleanStart = DateTime(project.startDate.year, project.startDate.month, project.startDate.day);
        final mondayOfToday = DateTime(cleanToday.year, cleanToday.month, cleanToday.day - (cleanToday.weekday - 1));
        final sundayOfToday = DateTime(mondayOfToday.year, mondayOfToday.month, mondayOfToday.day + 6);

        if (cleanToday.isAtSameMomentAs(cleanStart) || cleanToday.isAfter(cleanStart) || sundayOfToday.isAfter(cleanStart) || sundayOfToday.isAtSameMomentAs(cleanStart)) {
          final List<ScheduleModel> initialTasks = [];
          var tempDate = cleanStart;
          while (tempDate.isBefore(cleanToday)) {
            final diff = getDaysDifference(project.startDate, tempDate);
            final isRhythmRecovery = project.ongoingStyle == 'rhythm' && diff % 2 != 0;

            if (isRhythmRecovery) {
              initialTasks.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: 0,
                isRestDay: false,
                isRecoveryDay: true,
                completed: true,
                automaticRestDay: false,
                locked: false,
              ));
            } else {
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
            }
            tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
          }
          while (tempDate.isBefore(sundayOfToday) || tempDate.isAtSameMomentAs(sundayOfToday)) {
            final diff = getDaysDifference(project.startDate, tempDate);
            final isRhythmRecovery = project.ongoingStyle == 'rhythm' && diff % 2 != 0;

            if (isRhythmRecovery) {
              initialTasks.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: 0,
                isRestDay: false,
                isRecoveryDay: true,
                completed: true,
                automaticRestDay: false,
                locked: false,
              ));
            } else {
              initialTasks.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: project.dailyWordTarget,
                isRestDay: false,
                completed: false,
                automaticRestDay: false,
                locked: false,
              ));
            }
            tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
          }
          await schedRepo.insertSchedules(initialTasks);
        }
        continue;
      }

      // Case 2: Finalize past schedules (convert to automatic Rest Days if not completed)
      final logRepo = _ref.read(dailyLogRepositoryProvider);
      final List<ScheduleModel> toUpdate = [];
      
      bool ongoingFrozen = false;
      for (final s in schedules) {
        if (s.date.isBefore(cleanToday) && !s.completed && (!s.isRestDay || s.plannedWords > 0)) {
          final existingLogForRollover = await logRepo.getLogForDate(project.id, s.date);
          final backlogCreatedVal = existingLogForRollover?.backlogCreated ?? 0;
          if (backlogCreatedVal != 0) {
            continue;
          }

          if (project.ongoingStyle == 'rhythm') {
            final activeStreak = project.projectStreak;
            final settingsRepo = _ref.read(settingsRepositoryProvider);
            var settings = await settingsRepo.getSettings();

            if (activeStreak >= 1 && settings.streakShields > 0 && !s.isShielded) {
              // Consume a Streak Shield
              settings = settings.copyWith(streakShields: settings.streakShields - 1);
              await settingsRepo.updateSettings(settings);

              // Set freeze state
              project = project.copyWith(
                frozenDate: s.date,
                freezeActivatedAt: DateTime.now(),
              );
              await projRepo.updateProject(project);

              // Save flag to show popup notification on home screen
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('streak_shield_used_pending', true);
              } catch (_) {}

              // Mark schedule row as shielded
              final updatedS = s.copyWith(isShielded: true, locked: true);
              toUpdate.add(updatedS);
              
              ongoingFrozen = true;
              break;
            }

            final existingLog = await logRepo.getLogForDate(project.id, s.date);
            final actual = existingLog?.actualWords ?? 0;
            final backlogCreated = s.plannedWords - actual;

            toUpdate.add(s.copyWith(
              locked: true,
            ));
            
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
                actualWords: actual,
                carryForwardWords: 0,
                backlogCreated: backlogCreated,
                completed: false,
                loggedAt: s.date,
              ));
            }
          } else {
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
      }
      if (ongoingFrozen) continue;

      // Case 3: Check for calendar gaps / future generation up to Sunday of current week
      final latestDate = schedules.fold<DateTime>(
        schedules.first.date,
        (latest, s) => s.date.isAfter(latest) ? s.date : latest,
      );
      final List<ScheduleModel> toInsert = [];

      final mondayOfToday = DateTime(cleanToday.year, cleanToday.month, cleanToday.day - (cleanToday.weekday - 1));
      final sundayOfToday = DateTime(mondayOfToday.year, mondayOfToday.month, mondayOfToday.day + 6);

      if (latestDate.isBefore(sundayOfToday)) {
        var tempDate = DateTime(latestDate.year, latestDate.month, latestDate.day + 1);
        while (tempDate.isBefore(sundayOfToday) || tempDate.isAtSameMomentAs(sundayOfToday)) {
          final diff = getDaysDifference(project.startDate, tempDate);
          final isRhythmRecovery = project.ongoingStyle == 'rhythm' && diff % 2 != 0;

          if (tempDate.isBefore(cleanToday)) {
            if (isRhythmRecovery) {
              toInsert.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: 0,
                isRestDay: false,
                isRecoveryDay: true,
                completed: true,
                automaticRestDay: false,
                locked: false,
              ));
            } else {
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
            }
          } else {
            if (isRhythmRecovery) {
              toInsert.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: 0,
                isRestDay: false,
                isRecoveryDay: true,
                completed: true,
                automaticRestDay: false,
                locked: false,
              ));
            } else {
              toInsert.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: project.dailyWordTarget,
                isRestDay: false,
                completed: false,
                automaticRestDay: false,
                locked: false,
              ));
            }
          }
          tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
        }
      } else {
        // Safety check: ensure all dates from cleanToday to sundayOfToday exist
        var tempDate = cleanToday;
        while (tempDate.isBefore(sundayOfToday) || tempDate.isAtSameMomentAs(sundayOfToday)) {
          final hasDate = schedules.any((s) => s.date.isAtSameMomentAs(tempDate));
          if (!hasDate) {
            final diff = getDaysDifference(project.startDate, tempDate);
            final isRhythmRecovery = project.ongoingStyle == 'rhythm' && diff % 2 != 0;

            if (isRhythmRecovery) {
              toInsert.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: 0,
                isRestDay: false,
                isRecoveryDay: true,
                completed: true,
                automaticRestDay: false,
                locked: false,
              ));
            } else {
              toInsert.add(ScheduleModel(
                id: uuid.v4(),
                projectId: project.id,
                date: tempDate,
                plannedWords: project.dailyWordTarget,
                isRestDay: false,
                completed: false,
                automaticRestDay: false,
                locked: false,
              ));
            }
          }
          tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
        }
      }

      if (toUpdate.isNotEmpty) {
        for (final s in toUpdate) {
          await schedRepo.updateSchedule(s);
        }
      }
      if (toInsert.isNotEmpty) {
        await schedRepo.insertSchedules(toInsert);
      }

      final activeStreak = await _calculateProjectStreak(project.id, cleanToday, schedRepo, logRepo);
      if (project.projectStreak != activeStreak) {
        final updatedProject = project.copyWith(
          projectStreak: activeStreak,
          updatedAt: DateTime.now(),
        );
        await projRepo.updateProject(updatedProject);
      }
    }
  }

  Future<void> syncFixedGoalBacklogs(List<ProjectModel> activeProjects) async {
    final schedRepo = _ref.read(scheduleRepositoryProvider);
    final logRepo = _ref.read(dailyLogRepositoryProvider);
    final projRepo = _ref.read(projectRepositoryProvider);
    final schedService = _ref.read(schedulingServiceProvider);
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);
    final uuid = const Uuid();

    // Track dates shielded globally in this sync run
    final Set<DateTime> shieldedDates = {};

    for (final proj in activeProjects) {
      if (proj.projectType == ProjectType.ongoing) continue;
      var project = proj;

      // Check for active/expired Streak Shield freeze
      bool hasActiveFreeze = false;
      if (project.frozenDate != null && project.freezeActivatedAt != null) {
        final elapsed = DateTime.now().difference(project.freezeActivatedAt!);
        if (elapsed < const Duration(hours: 24)) {
          hasActiveFreeze = true;
        } else {
          final frozenDate = project.frozenDate!;
          project = project.copyWith(
            projectStreak: 0,
            clearFreeze: true,
          );
          await projRepo.updateProject(project);

          // Clear isShielded on the expired schedule
          final expiredSched = await schedRepo.getScheduleForDate(project.id, frozenDate);
          if (expiredSched != null && expiredSched.isShielded) {
            await schedRepo.updateSchedule(expiredSched.copyWith(isShielded: false, locked: false));
          }
        }
      }
      if (hasActiveFreeze) continue;

      List<ScheduleModel> currentSchedules = await schedRepo.getSchedulesForProject(project.id);
      if (currentSchedules.isEmpty) continue;

      // Sort current schedules chronologically to find bounds
      currentSchedules.sort((a, b) => a.date.compareTo(b.date));

      final firstDate = currentSchedules.first.date;
      final cleanFirst = DateTime(firstDate.year, firstDate.month, firstDate.day);

      bool projectModified = false;
      List<ScheduleModel> schedulesToUpdateInDb = [];

      final durationDays = getDaysDifference(project.startDate, project.expectedFinishDate) + 1;

      int currentWeekNum = 1;
      int currentRemainingRestDays = project.restMode == RestMode.fixed
          ? 0
          : min(
              project.allowedRestDays,
              (project.currentWeek == 1
                  ? project.remainingRestDays
                  : schedService.getWeeklyAllocation(
                      totalRestDays: project.allowedRestDays,
                      durationDays: durationDays,
                      week: 1,
                    )),
            );

      var tempDate = cleanFirst;
      while (tempDate.isBefore(cleanToday)) {
        // 1. Check week boundary transitions
        final weekOfTempDate = (getDaysDifference(project.startDate, tempDate) ~/ 7) + 1;
        if (weekOfTempDate > currentWeekNum) {
          while (currentWeekNum < weekOfTempDate) {
            currentWeekNum++;
            if (currentWeekNum == project.currentWeek) {
              currentRemainingRestDays = min(project.allowedRestDays, project.remainingRestDays);
            } else {
              final weeklyAllocation = schedService.getWeeklyAllocation(
                totalRestDays: project.allowedRestDays,
                durationDays: durationDays,
                week: currentWeekNum,
              );
              if (project.restMode == RestMode.flexible) {
                currentRemainingRestDays = min(project.allowedRestDays, currentRemainingRestDays + weeklyAllocation);
              } else if (project.restMode == RestMode.adaptive) {
                currentRemainingRestDays = min(project.allowedRestDays, weeklyAllocation);
              }
            }
          }
          projectModified = true;
        }

        // 2. Find schedule for tempDate
        final List<ScheduleModel> matches = currentSchedules.where(
          (x) => x.date.year == tempDate.year && x.date.month == tempDate.month && x.date.day == tempDate.day
        ).toList();
        final s = matches.isNotEmpty ? matches.first : null;

        if (s != null) {
          if (s.isRestDay || s.automaticRestDay) {
            currentRemainingRestDays = currentRemainingRestDays - 1 < 0 ? 0 : currentRemainingRestDays - 1;
          } else if (!s.completed) {
            final existingLogForRollover = await logRepo.getLogForDate(project.id, s.date);
            final backlogCreatedVal = existingLogForRollover?.backlogCreated ?? 0;
            if (backlogCreatedVal != 0) {
              tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
              continue;
            }

            // Check if we can activate a Streak Shield freeze
            final activeStreak = project.projectStreak;
            final settingsRepo = _ref.read(settingsRepositoryProvider);
            var settings = await settingsRepo.getSettings();

            if (activeStreak >= 1 && settings.streakShields > 0 && !s.isShielded) {
              if (!shieldedDates.any((d) => d.year == s.date.year && d.month == s.date.month && d.day == s.date.day)) {
                settings = settings.copyWith(streakShields: settings.streakShields - 1);
                await settingsRepo.updateSettings(settings);
                shieldedDates.add(s.date);
              }

              // Set freeze state
              project = project.copyWith(
                frozenDate: s.date,
                freezeActivatedAt: DateTime.now(),
              );
              await projRepo.updateProject(project);

              // Save flag to show popup notification on home screen
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('streak_shield_used_pending', true);
              } catch (_) {}

              // Mark schedule row as shielded
              final updatedS = s.copyWith(isShielded: true, locked: true);
              schedulesToUpdateInDb.add(updatedS);
              
              // Break out of rollover since we are now frozen!
              projectModified = true;
              break;
            }

            final existingLog = await logRepo.getLogForDate(project.id, s.date);
            final actual = existingLog?.actualWords ?? 0;

            if (actual == 0) {
              bool hasRest = false;
              if (!s.locked && project.restMode == RestMode.adaptive) {
                final isAllowed = schedService.isRestDayAllowed(
                  schedules: currentSchedules,
                  targetDate: s.date,
                );
                hasRest = currentRemainingRestDays > 0 && isAllowed;
              }

              if (hasRest) {
                // Mark schedule as Rest Day
                final updatedS = s.copyWith(
                  isRestDay: true,
                  plannedWords: 0,
                  locked: true,
                  completed: false,
                  automaticRestDay: true,
                );
                
                currentSchedules = currentSchedules.map((x) => x.id == s.id ? updatedS : x).toList();
                schedulesToUpdateInDb.add(updatedS);

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

                currentRemainingRestDays--;
                projectModified = true;

                // Redistribute planned words starting from tomorrow
                final tomorrow = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
                final futureSchedules = currentSchedules
                    .where((x) => !x.locked && (x.date.isAfter(tempDate) || x.date.isAtSameMomentAs(tomorrow)))
                    .toList();
                final totalFuturePlannedWords = futureSchedules.fold<int>(0, (sum, x) => sum + x.plannedWords) + s.plannedWords;

                final restDaysUsed = currentSchedules.where((x) => (x.isRestDay || x.automaticRestDay) && (x.locked || x.date.isBefore(tomorrow))).length;

                final recalculated = schedService.recalculateFutureSchedule(
                  existingSchedules: currentSchedules,
                  recalculateFromDate: tomorrow,
                  newDailyTarget: project.dailyWordTarget,
                  totalRemainingWords: totalFuturePlannedWords,
                  fixedRestWeekdays: const [],
                  restMode: project.restMode,
                  allowedRestDaysBudget: project.allowedRestDays,
                  restDaysUsed: restDaysUsed,
                );

                currentSchedules = recalculated;
                for (final r in recalculated) {
                  if (!r.locked) {
                    schedulesToUpdateInDb.add(r);
                  }
                }
              } else {
                // Backlog creation for missed day
                final target = s.plannedWords;
                if (target > 0) {
                  final backlogCreated = target;
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
                      plannedWords: target,
                      actualWords: 0,
                      carryForwardWords: 0,
                      backlogCreated: backlogCreated,
                      completed: false,
                      loggedAt: s.date,
                    ));
                  }
                }
                final updatedS = s.copyWith(locked: true);
                currentSchedules = currentSchedules.map((x) => x.id == s.id ? updatedS : x).toList();
                schedulesToUpdateInDb.add(updatedS);
              }
            } else if (actual < s.plannedWords) {
              // Backlog remaining
              final backlogCreated = s.plannedWords - actual;
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
                  actualWords: actual,
                  carryForwardWords: 0,
                  backlogCreated: backlogCreated,
                  completed: false,
                  loggedAt: s.date,
                ));
              }
              final updatedS = s.copyWith(locked: true);
              currentSchedules = currentSchedules.map((x) => x.id == s.id ? updatedS : x).toList();
              schedulesToUpdateInDb.add(updatedS);
            }
          }
        }

        tempDate = DateTime(tempDate.year, tempDate.month, tempDate.day + 1);
      }

      // Check today's week transition as well
      final weekOfToday = (getDaysDifference(project.startDate, cleanToday) ~/ 7) + 1;
      if (weekOfToday > currentWeekNum) {
        while (currentWeekNum < weekOfToday) {
          currentWeekNum++;
          if (currentWeekNum == project.currentWeek) {
            currentRemainingRestDays = min(project.allowedRestDays, project.remainingRestDays);
          } else {
            final weeklyAllocation = schedService.getWeeklyAllocation(
              totalRestDays: project.allowedRestDays,
              durationDays: durationDays,
              week: currentWeekNum,
            );
            if (project.restMode == RestMode.flexible) {
              currentRemainingRestDays = min(project.allowedRestDays, currentRemainingRestDays + weeklyAllocation);
            } else if (project.restMode == RestMode.adaptive) {
              currentRemainingRestDays = min(project.allowedRestDays, weeklyAllocation);
            }
          }
        }
        projectModified = true;
      }

      // Save schedules to DB
      if (schedulesToUpdateInDb.isNotEmpty) {
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

      final activeStreak = await _calculateProjectStreak(project.id, cleanToday, schedRepo, logRepo);

      if (project.backlogWords != calculatedBacklog ||
          project.currentWeek != currentWeekNum ||
          project.remainingRestDays != currentRemainingRestDays ||
          project.projectStreak != activeStreak ||
          projectModified) {
        final updatedProject = project.copyWith(
          backlogWords: calculatedBacklog,
          currentWeek: currentWeekNum,
          remainingRestDays: currentRemainingRestDays,
          projectStreak: activeStreak,
          updatedAt: DateTime.now(),
        );
        await projRepo.updateProject(updatedProject);
      }
    }
  }

  Future<int> _calculateProjectStreak(
    String projectId,
    DateTime cleanToday,
    ScheduleRepository schedRepo,
    DailyLogRepository logRepo,
  ) async {
    int streak = 0;
    var checkDate = DateTime(cleanToday.year, cleanToday.month, cleanToday.day - 1);
    while (true) {
      final sched = await schedRepo.getScheduleForDate(projectId, checkDate);
      if (sched == null) break;
      if (sched.isRestDay || sched.isShielded || sched.isRecoveryDay) {
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
        continue;
      }
      final log = await logRepo.getLogForDate(projectId, checkDate);
      final completed = log?.completed ?? false;
      if (completed) {
        streak++;
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      } else {
        break;
      }
    }
    return streak;
  }
}
