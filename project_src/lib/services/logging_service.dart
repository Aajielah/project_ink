import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/daily_log.dart';
import '../models/schedule.dart';
import '../models/statistics.dart';
import '../repositories/project_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/statistics_repository.dart';

class LoggingService {
  final ProjectRepository _projectRepo;
  final ScheduleRepository _scheduleRepo;
  final DailyLogRepository _logRepo;
  final StatisticsRepository _statsRepo;

  const LoggingService(
    this._projectRepo,
    this._scheduleRepo,
    this._logRepo,
    this._statsRepo,
  );

  /// Logs writing progress for a project on a specific date.
  /// Handles Carry-Forward, Backlog creation, Streaks, and Statistics updates.
  Future<void> logWords({
    required String projectId,
    required DateTime date,
    required int actualWords,
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
    } else if (schedule.locked) {
      throw StateError('Completed days are locked and cannot be changed.');
    }

    final plannedWords = schedule.plannedWords;
    final isExcess = actualWords > plannedWords;
    final isUnder = actualWords < plannedWords;
    final excessWords = isExcess ? actualWords - plannedWords : 0;
    final backlogCreated = isUnder ? plannedWords - actualWords : 0;
    final isCompleted = actualWords >= plannedWords;

    // 3. Create/Update Daily Log row
    final existingLog = await _logRepo.getLogForDate(projectId, cleanDate);
    final prevLogWords = existingLog?.actualWords ?? 0;
    final prevBacklogCreated = existingLog?.backlogCreated ?? 0;
    
    final dailyLog = DailyLogModel(
      id: existingLog?.id ?? uuid.v4(),
      projectId: projectId,
      scheduleId: schedule.id,
      date: cleanDate,
      plannedWords: plannedWords,
      actualWords: actualWords,
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

    // 5. Carry Forward Logic (if there are excess words)
    if (excessWords > 0) {
      final futureSchedules = await _scheduleRepo.getSchedulesForProject(projectId);
      final List<ScheduleModel> schedulesToUpdate = [];
      int remainingExcess = excessWords;

      for (final sched in futureSchedules) {
        if (sched.date.isAfter(cleanDate) && !sched.locked && !sched.isRestDay && !sched.completed) {
          final planned = sched.plannedWords;
          if (planned > 0) {
            final reduction = min(remainingExcess, planned);
            final newPlanned = planned - reduction;
            
            schedulesToUpdate.add(sched.copyWith(
              plannedWords: newPlanned,
              completed: newPlanned == 0, // mark complete if reduced to 0
            ));
            
            remainingExcess -= reduction;
            if (remainingExcess <= 0) break;
          }
        }
      }
      
      if (schedulesToUpdate.isNotEmpty) {
        await _scheduleRepo.insertSchedules(schedulesToUpdate);
      }
    }

    // 6. Recalculate Project Progress & Backlog
    // Subtract previous logged words (if updating log) and add new logged words
    final wordDiff = actualWords - prevLogWords;
    final newWrittenWords = project.writtenWords + wordDiff;
    final newRemainingWords = max(0, project.targetWords - newWrittenWords);
    
    ProjectStatus newStatus = project.status;
    DateTime? actualFinish;
    if (newRemainingWords == 0) {
      newStatus = ProjectStatus.completed;
      actualFinish = cleanDate;
    } else if (project.status == ProjectStatus.upcoming) {
      newStatus = ProjectStatus.active;
    }

    // Streaks calculation
    int newStreak = project.projectStreak;
    if (isCompleted) {
      newStreak++;
    } else {
      newStreak = 0; // broke the streak
    }
    final newLongestStreak = max(project.longestProjectStreak, newStreak);

    final updatedProject = project.copyWith(
      writtenWords: newWrittenWords,
      remainingWords: newRemainingWords,
      backlogWords: max(0, project.backlogWords - prevBacklogCreated + backlogCreated),
      status: newStatus,
      actualFinishDate: actualFinish,
      projectStreak: newStreak,
      longestProjectStreak: newLongestStreak,
      updatedAt: DateTime.now(),
    );

    await _projectRepo.updateProject(updatedProject);

    // 7. Recalculate Global Statistics
    final stats = await _statsRepo.getStatistics();
    
    // Determine if today constitutes a global writing day
    // (if they wrote any words across all logs on this day)
    int newWritingDays = stats.writingDays;
    if (prevLogWords == 0 && actualWords > 0) {
      newWritingDays++;
    }

    // Global streak
    int newGlobalStreak = stats.currentGlobalStreak;
    if (isCompleted) {
      newGlobalStreak++;
    } else {
      newGlobalStreak = 0;
    }
    final newLongestGlobal = max(stats.longestGlobalStreak, newGlobalStreak);

    final newProjectsCompleted = newStatus == ProjectStatus.completed &&
            project.status != ProjectStatus.completed
        ? stats.projectsCompleted + 1 
        : stats.projectsCompleted;

    final newLifetimeWords = stats.lifetimeWords + wordDiff;
    final double newAvg = newWritingDays > 0 ? newLifetimeWords / newWritingDays : 0.0;

    final updatedStats = stats.copyWith(
      lifetimeWords: newLifetimeWords,
      writingDays: newWritingDays,
      averageWordsPerDay: newAvg,
      currentGlobalStreak: newGlobalStreak,
      longestGlobalStreak: newLongestGlobal,
      projectsCompleted: newProjectsCompleted,
      currentBacklog: max(0, stats.currentBacklog - prevBacklogCreated + backlogCreated),
      restDaysUsed: stats.restDaysUsed +
          (schedule.isRestDay && existingLog == null ? 1 : 0),
    );

    await _statsRepo.updateStatistics(updatedStats);
  }
}
