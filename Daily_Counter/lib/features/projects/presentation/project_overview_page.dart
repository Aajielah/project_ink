import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import 'project_overview_controller.dart';

class ProjectOverviewPage extends ConsumerWidget {
  final String projectId;
  const ProjectOverviewPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(projectId) ?? 0;
    final overviewAsync = ref.watch(projectOverviewControllerProvider(id));
    final theme = Theme.of(context);

    return overviewAsync.when(
      data: (state) {
        if (state.project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Goal Overview')),
            body: Center(child: Text(state.error ?? 'Goal not found')),
          );
        }

        final project = state.project!;
        final categoryColor = CategoryUtils.getColor(project.category, context);
        final categoryIcon = CategoryUtils.getIcon(project.category);
        final today = DurationUtils.normalizeDate(DateTime.now());
        final todayRecord = state.getRecordForDate(today);
        final isTodayCompleted = todayRecord != null && todayRecord.status == 'completed';

        return Scaffold(
          appBar: AppBar(
            title: Text(project.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
                onPressed: () => context.push('/history/$projectId'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Edit Goal',
                onPressed: () async {
                  await context.push('/edit/$projectId');
                  ref.read(projectOverviewControllerProvider(id).notifier).refresh();
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(categoryIcon, color: categoryColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  project.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mode Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: project.trackingMode == 'strict'
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.trackingMode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: project.trackingMode == 'strict' ? Colors.red : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Motivation Quote
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.format_quote_rounded, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                project.motivation,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Progress Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${project.completedDays} / ${project.targetDays} Days',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: state.completionRate,
                          minHeight: 10,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(categoryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Started: ${DurationUtils.formatDate(project.startDate)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'Target End: ${DurationUtils.formatDate(project.endDate)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Progress Swipe Carousel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel Header with Prev/Next
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () =>
                                ref.read(projectOverviewControllerProvider(id).notifier).previousWeek(),
                          ),
                          Text(
                            _formatWeekRange(state.currentWeekMonday),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () =>
                                ref.read(projectOverviewControllerProvider(id).notifier).nextWeek(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 7 Days Row
                      _buildWeekDaysRow(context, ref, state, project),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Metrics Grid
              Row(
                children: [
                  _buildMetricCard(
                    context,
                    title: 'Completed',
                    value: '${project.completedDays}',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    context,
                    title: 'Missed',
                    value: '${state.missedDaysCount}',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    context,
                    title: 'Remaining',
                    value: '${(project.targetDays - project.completedDays).clamp(0, project.targetDays)}',
                    icon: Icons.timelapse_rounded,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Check-in for Today CTA
              if (!isTodayCompleted && project.status == 'active') ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(projectOverviewControllerProvider(id).notifier).checkInToday(),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Check-in for Today'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (isTodayCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Completed for today! Keep the streak alive.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  String _formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (monday.month == sunday.month) {
      return '${monday.day} – ${sunday.day} ${months[monday.month - 1]} ${monday.year}';
    }
    return '${monday.day} ${months[monday.month - 1]} – ${sunday.day} ${months[sunday.month - 1]} ${sunday.year}';
  }

  Widget _buildWeekDaysRow(
    BuildContext context,
    WidgetRef ref,
    ProjectOverviewState state,
    dynamic project,
  ) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DurationUtils.normalizeDate(DateTime.now());
    final normStart = DurationUtils.normalizeDate(project.startDate);
    final isTrust = project.trackingMode == 'trust';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = state.currentWeekMonday.add(Duration(days: index));
        final normDay = DurationUtils.normalizeDate(dayDate);
        final isToday = normDay == today;
        final isFuture = normDay.isAfter(today);
        final isBeforeStart = normDay.isBefore(normStart);

        final isPaused = state.isDatePaused(normDay);
        final record = state.getRecordForDate(normDay);
        final isExplicitCompleted = record != null && record.status == 'completed';
        final isExplicitMissed = record != null && record.status == 'missed';

        // Trust mode defaults past unmarked days as completed unless paused
        final isCompleted = !isPaused && (isExplicitCompleted || (isTrust && !isBeforeStart && !isFuture && !isExplicitMissed));
        final isMissed = !isPaused && isExplicitMissed;

        Color circleColor = Colors.grey.withValues(alpha: 0.1);
        Color textColor = Colors.grey;
        Widget statusIcon = Text(
          '${dayDate.day}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
        );

        if (isBeforeStart || isFuture) {
          circleColor = Colors.grey.withValues(alpha: 0.05);
          textColor = Colors.grey.withValues(alpha: 0.4);
        } else if (isPaused) {
          circleColor = Colors.amber.withValues(alpha: 0.15);
          textColor = Colors.amber;
          statusIcon = const Icon(Icons.pause_rounded, size: 16, color: Colors.amber);
        } else if (isMissed) {
          circleColor = Colors.red.withValues(alpha: 0.15);
          textColor = Colors.red;
          statusIcon = const Icon(Icons.close_rounded, size: 16, color: Colors.red);
        } else if (isCompleted) {
          circleColor = Colors.green.withValues(alpha: 0.15);
          textColor = Colors.green;
          statusIcon = const Icon(Icons.check_rounded, size: 16, color: Colors.green);
        }

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _handleDayTap(
            context,
            ref,
            project.id,
            normDay,
            isToday: isToday,
            isFuture: isFuture,
            isBeforeStart: isBeforeStart,
            isPaused: isPaused,
            isTrust: isTrust,
            isCompleted: isCompleted,
            isMissed: isMissed,
          ),
          child: Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                statusIcon,
              ],
            ),
          ),
        );
      }),
    );
  }

  void _handleDayTap(
    BuildContext context,
    WidgetRef ref,
    int projectId,
    DateTime date, {
    required bool isToday,
    required bool isFuture,
    required bool isBeforeStart,
    required bool isPaused,
    required bool isTrust,
    required bool isCompleted,
    required bool isMissed,
  }) async {
    if (isFuture) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot check in for future dates.')),
      );
      return;
    }
    if (isBeforeStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date is before project start date.')),
      );
      return;
    }
    if (isPaused) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking was on hold during this pause interval.')),
      );
      return;
    }

    if (isToday) {
      if (!isCompleted) {
        await ref.read(projectOverviewControllerProvider(projectId).notifier).checkInToday();
      }
      return;
    }

    // Past Days
    if (isMissed) {
      // Option 1 rule: locked missed day
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missed days are permanently locked and cannot be changed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isTrust && isCompleted) {
      // In Trust Mode, user can change completed day to missed
      final shouldMarkMissed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark Day as Missed?'),
          content: Text(
            'Under Trust Mode (Option 1), once you mark ${DurationUtils.formatDate(date)} as missed, it is permanently locked and cannot be changed back to completed.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark as Missed'),
            ),
          ],
        ),
      );

      if (shouldMarkMissed == true) {
        await ref.read(projectOverviewControllerProvider(projectId).notifier).markDayAsMissed(date);
      }
    } else if (!isTrust && !isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Strict Mode does not allow retroactively marking past days.')),
      );
    }
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
