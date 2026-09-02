import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/services/day_finalizer_service.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/daily_record.dart';

class HomeController extends AsyncNotifier<List<Project>> {
  @override
  FutureOr<List<Project>> build() async {
    return _loadActiveTodayProjects();
  }

  Future<List<Project>> _loadActiveTodayProjects() async {
    final db = ref.watch(databaseServiceProvider);
    final projects = await db.getAllProjects();
    final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());

    final List<Project> activeToday = [];
    for (var project in projects) {
      // 1. Must be active status
      if (project.status != 'active') continue;

      // 2. Start date must be on or before logical today
      final normalizedStart = DurationUtils.normalizeDate(project.startDate);
      if (normalizedStart.isAfter(logicalToday)) continue;

      // 3. Must NOT have a completed or missed record for logical today
      final record = await db.getRecordForDate(project.id, logicalToday);
      if (record != null && (record.status == 'completed' || record.status == 'missed')) {
        continue;
      }

      activeToday.add(project);
    }
    return activeToday;
  }

  Future<void> completeProject(int projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseServiceProvider);
      final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());

      // Save completed record for the active logical tracking date
      var record = await db.getRecordForDate(projectId, logicalToday);
      if (record == null) {
        record = DailyRecord()
          ..projectId = projectId
          ..date = logicalToday
          ..status = 'completed'
          ..automatic = false
          ..modified = false
          ..createdAt = DateTime.now();
        await db.saveRecord(record);

        final project = await db.getProject(projectId);
        if (project != null) {
          project.completedDays += 1;
          if (project.completedDays >= project.targetDays) {
            project.status = 'completed';
          }
          await db.saveProject(project);
        }
      }

      return _loadActiveTodayProjects();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadActiveTodayProjects());
  }
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, List<Project>>(() {
  return HomeController();
});
