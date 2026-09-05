import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/services/day_finalizer_service.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/daily_record.dart';

class HomeDashboardData {
  final List<Project> dueToday;
  final List<Project> completedToday;
  final List<Project> upcoming;
  final int totalActive;
  final int totalPaused;
  final int totalCompleted;
  final int totalAllTimeCheckIns;

  HomeDashboardData({
    required this.dueToday,
    required this.completedToday,
    required this.upcoming,
    required this.totalActive,
    required this.totalPaused,
    required this.totalCompleted,
    required this.totalAllTimeCheckIns,
  });
}

class HomeController extends AsyncNotifier<HomeDashboardData> {
  @override
  FutureOr<HomeDashboardData> build() async {
    return _loadDashboardData();
  }

  Future<HomeDashboardData> _loadDashboardData() async {
    final db = ref.watch(databaseServiceProvider);
    final projects = await db.getAllProjects();
    final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());

    final List<Project> dueToday = [];
    final List<Project> completedToday = [];
    final List<Project> upcoming = [];
    int activeCount = 0;
    int pausedCount = 0;
    int completedCount = 0;
    int totalCheckIns = 0;

    for (var project in projects) {
      if (project.status == 'active') {
        activeCount++;
      } else if (project.status == 'paused') {
        pausedCount++;
      } else if (project.status == 'completed') {
        completedCount++;
      }

      final records = await db.getRecordsForProject(project.id);
      totalCheckIns += records.where((r) => r.status == 'completed').length;

      if (project.status != 'active') continue;

      final normalizedStart = DurationUtils.normalizeDate(project.startDate);
      if (normalizedStart.isAfter(logicalToday)) {
        upcoming.add(project);
        continue;
      }

      final todayRecord = await db.getRecordForDate(project.id, logicalToday);
      if (todayRecord != null && todayRecord.status == 'completed') {
        completedToday.add(project);
      } else if (todayRecord == null || (todayRecord.status != 'completed' && todayRecord.status != 'missed')) {
        dueToday.add(project);
      }
    }

    return HomeDashboardData(
      dueToday: dueToday,
      completedToday: completedToday,
      upcoming: upcoming,
      totalActive: activeCount,
      totalPaused: pausedCount,
      totalCompleted: completedCount,
      totalAllTimeCheckIns: totalCheckIns,
    );
  }

  Future<void> completeProject(int projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseServiceProvider);
      final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());

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
      } else if (record.status != 'completed') {
        record.status = 'completed';
        record.modified = true;
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

      return _loadDashboardData();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadDashboardData());
  }
}

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeDashboardData>(() {
  return HomeController();
});
