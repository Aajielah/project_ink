import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../shared/date_utils.dart';
import 'notification_service.dart';

class ProjectLifecycleService {
  final ProjectRepository _projectRepo;
  final DailyLogRepository _dailyLogRepo;

  ProjectLifecycleService(this._projectRepo, this._dailyLogRepo);

  /// Checks active projects for inactivity >= 7 days.
  /// Automatically pauses them and fires a push notification.
  Future<void> checkAndPauseInactiveProjects(List<ProjectModel> projects) async {
    final today = getLogicalToday();
    final cleanToday = DateTime(today.year, today.month, today.day);

    for (final p in projects) {
      if (p.status != ProjectStatus.active) continue;

      DateTime? resumedAt;
      try {
        final prefs = await SharedPreferences.getInstance();
        final resumedAtStr = prefs.getString('project_resumed_at_${p.id}');
        if (resumedAtStr != null) {
          resumedAt = DateTime.tryParse(resumedAtStr);
        }
      } catch (_) {}

      final logs = await _dailyLogRepo.getLogsForProject(p.id);
      final successfulLogs = logs.where((l) => l.actualWords > 0).toList();

      DateTime lastActivity;
      if (successfulLogs.isNotEmpty) {
        lastActivity = successfulLogs.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date;
      } else {
        final createdAt = p.createdAt;
        lastActivity = p.startDate.isAfter(createdAt) ? p.startDate : createdAt;
      }

      if (resumedAt != null && resumedAt.isAfter(lastActivity)) {
        lastActivity = resumedAt;
      }

      final inactivityDays = getDaysDifference(lastActivity, cleanToday);

      if (inactivityDays >= 7) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('project_resumed_at_${p.id}');
        } catch (_) {}

        final updatedProject = p.copyWith(
          status: ProjectStatus.paused,
          updatedAt: DateTime.now(),
        );
        await _projectRepo.updateProject(updatedProject);

        await NotificationService.instance.showInstantNotification(
          p.id.hashCode & 0x7FFFFFFF,
          'Project Paused due to Inactivity',
          '"${p.name}" has been paused automatically after 7 days of inactivity.',
        );
      }
    }
  }
}
