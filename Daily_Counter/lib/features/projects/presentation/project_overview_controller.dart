import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/services/day_finalizer_service.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import '../../../shared/models/daily_record.dart';
import '../../../shared/models/pause.dart';

class ProjectOverviewState {
  final Project? project;
  final List<DailyRecord> records;
  final List<Pause> pauses;
  final DateTime currentWeekMonday;
  final bool isLoading;
  final String? error;

  ProjectOverviewState({
    this.project,
    this.records = const [],
    this.pauses = const [],
    required this.currentWeekMonday,
    this.isLoading = true,
    this.error,
  });

  ProjectOverviewState copyWith({
    Project? project,
    List<DailyRecord>? records,
    List<Pause>? pauses,
    DateTime? currentWeekMonday,
    bool? isLoading,
    String? error,
  }) {
    return ProjectOverviewState(
      project: project ?? this.project,
      records: records ?? this.records,
      pauses: pauses ?? this.pauses,
      currentWeekMonday: currentWeekMonday ?? this.currentWeekMonday,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  DailyRecord? getRecordForDate(DateTime date) {
    final norm = DurationUtils.normalizeDate(date);
    for (var r in records) {
      if (DurationUtils.normalizeDate(r.date) == norm) {
        return r;
      }
    }
    return null;
  }

  bool isDatePaused(DateTime date) {
    return DayFinalizerService.isDateInPause(date, pauses);
  }

  int get missedDaysCount {
    return records.where((r) => r.status == 'missed').length;
  }

  int get completedDaysCount {
    return records.where((r) => r.status == 'completed').length;
  }

  double get completionRate {
    if (project == null || project!.targetDays == 0) return 0.0;
    return (project!.completedDays / project!.targetDays).clamp(0.0, 1.0);
  }
}

class ProjectOverviewController extends FamilyAsyncNotifier<ProjectOverviewState, int> {
  @override
  FutureOr<ProjectOverviewState> build(int projectId) async {
    final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final monday = logicalToday.subtract(Duration(days: logicalToday.weekday - 1));
    return _loadData(projectId, monday);
  }

  Future<ProjectOverviewState> _loadData(int projectId, DateTime weekMonday) async {
    final db = ref.read(databaseServiceProvider);
    final project = await db.getProject(projectId);
    if (project == null) {
      return ProjectOverviewState(
        currentWeekMonday: weekMonday,
        isLoading: false,
        error: 'Goal not found',
      );
    }

    final records = await db.getRecordsForProject(projectId);
    final pauses = await db.getPausesForProject(projectId);

    return ProjectOverviewState(
      project: project,
      records: records,
      pauses: pauses,
      currentWeekMonday: weekMonday,
      isLoading: false,
    );
  }

  void previousWeek() {
    final current = state.value;
    if (current == null) return;
    final newMonday = current.currentWeekMonday.subtract(const Duration(days: 7));
    state = AsyncValue.data(current.copyWith(currentWeekMonday: newMonday));
  }

  void nextWeek() {
    final current = state.value;
    if (current == null) return;
    final newMonday = current.currentWeekMonday.add(const Duration(days: 7));
    state = AsyncValue.data(current.copyWith(currentWeekMonday: newMonday));
  }

  void jumpToCurrentWeek() {
    final current = state.value;
    if (current == null) return;
    final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final monday = logicalToday.subtract(Duration(days: logicalToday.weekday - 1));
    state = AsyncValue.data(current.copyWith(currentWeekMonday: monday));
  }

  Future<void> checkInToday() async {
    final current = state.value;
    if (current == null || current.project == null) return;

    final db = ref.read(databaseServiceProvider);
    final logicalToday = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final projectId = current.project!.id;

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

      final p = current.project!;
      p.completedDays += 1;
      if (p.completedDays >= p.targetDays) {
        p.status = 'completed';
      }
      await db.saveProject(p);
    } else if (record.status != 'completed') {
      record.status = 'completed';
      record.modified = true;
      await db.saveRecord(record);

      final p = current.project!;
      p.completedDays += 1;
      if (p.completedDays >= p.targetDays) {
        p.status = 'completed';
      }
      await db.saveProject(p);
    }

    state = AsyncValue.data(await _loadData(projectId, current.currentWeekMonday));
  }

  Future<void> markDayAsMissed(DateTime date) async {
    final current = state.value;
    if (current == null || current.project == null) return;

    final db = ref.read(databaseServiceProvider);
    final normDate = DurationUtils.normalizeDate(date);
    final projectId = current.project!.id;

    var record = await db.getRecordForDate(projectId, normDate);
    final isTrust = current.project!.trackingMode == 'trust';
    final wasPreviouslyCompleted = (record != null && record.status == 'completed') ||
        (record == null && isTrust);

    if (record == null) {
      record = DailyRecord()
        ..projectId = projectId
        ..date = normDate
        ..status = 'missed'
        ..automatic = false
        ..modified = true
        ..createdAt = DateTime.now();
    } else {
      record.status = 'missed';
      record.modified = true;
    }
    await db.saveRecord(record);

    if (wasPreviouslyCompleted) {
      final p = current.project!;
      if (p.completedDays > 0) {
        p.completedDays -= 1;
        await db.saveProject(p);
      }
    }

    state = AsyncValue.data(await _loadData(projectId, current.currentWeekMonday));
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null || current.project == null) return;
    state = AsyncValue.data(await _loadData(current.project!.id, current.currentWeekMonday));
  }
}

final projectOverviewControllerProvider =
    AsyncNotifierProvider.family<ProjectOverviewController, ProjectOverviewState, int>(
  () => ProjectOverviewController(),
);
