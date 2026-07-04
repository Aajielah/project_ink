import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/daily_log.dart';
import '../models/schedule.dart';
import '../models/statistics.dart';
import '../repositories/project_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/statistics_repository.dart';
import '../shared/providers.dart';

class LoggingService {
  final ProjectRepository _projectRepo;
  final ScheduleRepository _scheduleRepo;
  final DailyLogRepository _logRepo;
  final StatisticsRepository _statsRepo;
  final Ref? _ref;

  const LoggingService(
    this._projectRepo,
    this._scheduleRepo,
    this._logRepo,
    this._statsRepo, [
    this._ref,
  ]);

  /// Logs writing progress for a project on a specific date.
  /// Handles Carry-Forward, Backlog creation, Streaks, and Statistics updates.
  /// Returns [true] if the writing goal is completed today.
  Future<bool> logWords({
    required String projectId,
    required DateTime date,
    required int actualWords,
    bool isAdditive = true,
  }) async {
    if (actualWords < 0) {
      throw ArgumentError('Logged words cannot be negative.');
    }

    final cleanDate = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (cleanDate != today) {
      throw StateError('Words can only be logged for today.');
    }
    
    // 1. Fetch the project
    final project = await _projectRepo.getProjectById(projectId);
    if (project == null) {
      throw StateError('Project not found.');
    }
    if (project.status == ProjectStatus.completed) {
      throw StateError('Cannot log words on a completed project.');
    }

    // 2. Fetch today's schedule row
    ScheduleModel? schedule = await _scheduleRepo.getScheduleForDate(projectId, cleanDate);
    final uuid = const Uuid();

    if (schedule == null) {
      // If no schedule exists (e.g. log on a day outside range), create a dynamic one
      schedule = ScheduleModel(
        id: uuid.v4(),
        projectId: projectId,
        date: cleanDate,
        plannedWords: 0,
        isRestDay: true,
        completed: false,
        automaticRestDay: false,
        locked: false,
      );
      await _scheduleRepo.insertSchedules([schedule]);
    }

    // 3. Create/Update Daily Log row
    final existingLog = await _logRepo.getLogForDate(projectId, cleanDate);
    final prevLogWords = existingLog?.actualWords ?? 0;
    final prevBacklogCreated = existingLog?.backlogCreated ?? 0;

    final newActualWords = isAdditive ? (prevLogWords + actualWords) : actualWords;

    final isOngoing = project.projectType == ProjectType.ongoing;
    final plannedWords = schedule.plannedWords;
    final isExcess = newActualWords > plannedWords;
    final excessWords = isExcess ? newActualWords - plannedWords : 0;
    final backlogCreated = 0; // Today is still in progress, backlog is only generated after rollover.
    final isCompleted = newActualWords >= plannedWords;
    
    final dailyLog = DailyLogModel(
      id: existingLog?.id ?? uuid.v4(),
      projectId: projectId,
      scheduleId: schedule.id,
      date: cleanDate,
      plannedWords: plannedWords,
      actualWords: newActualWords,
      carryForwardWords: excessWords,
      backlogCreated: backlogCreated,
      completed: isCompleted,
      loggedAt: DateTime.now(),
    );

    await _logRepo.insertLog(dailyLog);

    // 4. Update today's schedule row to completed and locked
    final updatedSchedule = schedule.copyWith(
      completed: isCompleted,
      locked: true,
    );
    await _scheduleRepo.updateSchedule(updatedSchedule);

    // 5. Carry Forward Calculation (cap to one day's target, store as pending credit)
    int pendingCarryForward = 0;
    if (excessWords > 0 && !isOngoing) {
      pendingCarryForward = min(excessWords, project.dailyWordTarget);
    }

    // 6. Recalculate Project Progress & Backlog
    final wordDiff = newActualWords - prevLogWords;
    final newWrittenWords = project.writtenWords + wordDiff;
    final newRemainingWords = isOngoing ? 0 : max(0, project.targetWords - newWrittenWords);
    
    ProjectStatus newStatus = project.status;
    DateTime? actualFinish;
    if (!isOngoing && newRemainingWords == 0) {
      newStatus = ProjectStatus.completed;
      actualFinish = cleanDate;
    } else if (project.status == ProjectStatus.upcoming) {
      newStatus = ProjectStatus.active;
    }

    // Streaks calculation
    final bool wasCompletedBefore = existingLog?.completed ?? false;
    
    int newStreak = project.projectStreak;
    final yesterdayStreak = await _calculateStreakBeforeToday(projectId, cleanDate);
    if (isCompleted) {
      if (!wasCompletedBefore) {
        newStreak = yesterdayStreak + 1;
      }
    } else {
      newStreak = yesterdayStreak; // keep streak up to yesterday since today is still ongoing
    }
    final newLongestStreak = max(project.longestProjectStreak, newStreak);

    final isProjectCompleted = !isOngoing && newRemainingWords == 0;
    final finalPendingCarryForward = isProjectCompleted ? 0 : pendingCarryForward;

    final updatedProject = project.copyWith(
      writtenWords: newWrittenWords,
      remainingWords: newRemainingWords,
      backlogWords: isOngoing ? 0 : max(0, project.backlogWords - prevBacklogCreated + backlogCreated),
      status: newStatus,
      actualFinishDate: actualFinish,
      projectStreak: newStreak,
      longestProjectStreak: newLongestStreak,
      pendingCarryForward: finalPendingCarryForward,
      updatedAt: DateTime.now(),
    );

    await _projectRepo.updateProject(updatedProject);

    // 7. Recalculate Global Statistics
    await _statsRepo.recalculateStatistics();

    if (_ref != null) {
      _ref!.invalidate(statisticsProvider);
      _ref!.invalidate(homeEncouragementProvider);
      _ref!.invalidate(homeQuoteProvider);
    }

    return isCompleted;
  }

  /// Automatically applies any pending carry forward credit to today's active writing task
  Future<void> checkAndApplyPendingCarryForward(List<ProjectModel> activeProjects) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final project in activeProjects) {
      if (project.pendingCarryForward > 0) {
        final schedule = await _scheduleRepo.getScheduleForDate(project.id, today);
        if (schedule != null && !schedule.isRestDay && !schedule.completed) {
          final credit = project.pendingCarryForward;
          
          // Reset the credit on the project first to prevent double application
          final updatedProj = project.copyWith(
            pendingCarryForward: 0,
            updatedAt: DateTime.now(),
          );
          await _projectRepo.updateProject(updatedProj);
          
          // Log the credit for today
          await logWords(
            projectId: project.id,
            date: today,
            actualWords: credit,
          );
        }
      }
    }
  }

  Future<int> _calculateStreakBeforeToday(String projectId, DateTime cleanToday) async {
    int streak = 0;
    var checkDate = cleanToday.subtract(const Duration(days: 1));
    while (true) {
      final sched = await _scheduleRepo.getScheduleForDate(projectId, checkDate);
      if (sched == null) break;
      if (sched.isRestDay) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      final log = await _logRepo.getLogForDate(projectId, checkDate);
      final completed = log?.completed ?? false;
      if (completed) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
