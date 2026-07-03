import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../models/schedule.dart';
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
    final today = DateTime.now();
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

      // Case 2: Finalize past unlocked schedules (convert to automatic Rest Days)
      final List<ScheduleModel> toUpdate = [];
      for (final s in schedules) {
        if (s.date.isBefore(cleanToday) && !s.locked) {
          toUpdate.add(s.copyWith(
            plannedWords: 0,
            isRestDay: true,
            automaticRestDay: true,
            completed: false,
            locked: true,
          ));
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
}
