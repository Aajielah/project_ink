import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/day_finalizer_service.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import 'project_overview_controller.dart';

class ProjectOverviewPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectOverviewPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectOverviewPage> createState() => _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends ConsumerState<ProjectOverviewPage> {
  bool _showFullMatrix = false;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.projectId);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal Overview')),
        body: const Center(child: Text('Invalid Goal ID')),
      );
    }

    final stateAsync = ref.watch(projectOverviewControllerProvider(id));

    return stateAsync.when(
      data: (state) {
        if (state.project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Goal Overview')),
            body: Center(child: Text(state.error ?? 'Goal not found')),
          );
        }

        final project = state.project!;
        final theme = Theme.of(context);
        final categoryColor = CategoryUtils.getColor(project.category, context);

        final normStart = DurationUtils.normalizeDate(project.startDate);
        final normEnd = DurationUtils.normalizeDate(project.endDate);
        final startMonday = normStart.subtract(Duration(days: normStart.weekday - 1));
        final endMonday = normEnd.subtract(Duration(days: normEnd.weekday - 1));

        final canGoPrev = state.currentWeekMonday.isAfter(startMonday);
        final canGoNext = state.currentWeekMonday.isBefore(endMonday);

        final totalWeeks = (endMonday.difference(startMonday).inDays ~/ 7) + 1;
        final currentWeekIndex = ((state.currentWeekMonday.difference(startMonday).inDays ~/ 7) + 1).clamp(1, totalWeeks);

        final today = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
        final todayRecord = state.getRecordForDate(today);
        final isTodayCompleted = todayRecord != null && todayRecord.status == 'completed';

        return Scaffold(
          appBar: AppBar(
            title: Text(project.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => context.push('/history/$id'),
                tooltip: 'History & Logs',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push('/edit/$id');
                  ref.read(projectOverviewControllerProvider(id).notifier).refresh();
                },
                tooltip: 'Edit Goal',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CategoryUtils.getIcon(project.category),
                            color: categoryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  project.category,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: project.trackingMode == 'strict'
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              project.trackingMode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: project.trackingMode == 'strict'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (project.motivation.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
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
                            'Goal Progress',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Day ${project.completedDays} / ${project.targetDays}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                            'Start: ${DurationUtils.formatDate(project.startDate)}',
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

              // View Mode Selector (Week vs Full Matrix)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showFullMatrix ? 'Full Timeline (${project.targetDays} Days)' : 'Task Calendar',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: Icon(_showFullMatrix ? Icons.view_week_rounded : Icons.grid_view_rounded, size: 18),
                    label: Text(_showFullMatrix ? 'Show Week View' : 'Show All Days'),
                    onPressed: () => setState(() => _showFullMatrix = !_showFullMatrix),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Task Calendar Bounded to Start and End Date
              if (!_showFullMatrix)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bounded Prev / Next Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: canGoPrev
                                  ? () => ref
                                      .read(projectOverviewControllerProvider(id).notifier)
                                      .previousWeek()
                                  : null,
                              tooltip: 'Previous week of task',
                            ),
                            Column(
                              children: [
                                Text(
                                  'Week $currentWeekIndex of $totalWeeks',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  _formatWeekRange(state.currentWeekMonday),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: canGoNext
                                  ? () => ref
                                      .read(projectOverviewControllerProvider(id).notifier)
                                      .nextWeek()
                                  : null,
                              tooltip: 'Next week of task',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 7 Days Row strictly inside project boundaries
                        _buildWeekDaysRow(context, ref, state, project, normStart, normEnd),
                      ],
                    ),
                  ),
                )
              else
                _buildFullGoalMatrix(context, ref, state, project, normStart, normEnd),

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

              // Action Check-in button
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
    Project project,
    DateTime normStart,
    DateTime normEnd,
  ) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final isTrust = project.trackingMode == 'trust';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = state.currentWeekMonday.add(Duration(days: index));
        final normDay = DurationUtils.normalizeDate(dayDate);
        final isToday = normDay == today;
        final isFuture = normDay.isAfter(today);
        final isBeforeStart = normDay.isBefore(normStart);
        final isAfterEnd = normDay.isAfter(normEnd);

        if (isBeforeStart || isAfterEnd) {
          // Outside this task's lifetime: render subtle empty slot
          return Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(dayLabels[index], style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha: 0.3))),
                const SizedBox(height: 6),
                Text('—', style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.3))),
              ],
            ),
          );
        }

        final isPaused = state.isDatePaused(normDay);
        final record = state.getRecordForDate(normDay);
        final isExplicitCompleted = record != null && record.status == 'completed';
        final isExplicitMissed = record != null && record.status == 'missed';

        final isCompleted = !isPaused && (isExplicitCompleted || (isTrust && !isFuture && !isExplicitMissed));
        final isMissed = !isPaused && isExplicitMissed;

        Color circleColor = Colors.grey.withValues(alpha: 0.1);
        Color textColor = Colors.grey;
        Widget statusIcon = Text(
          '${dayDate.day}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
        );

        if (isFuture) {
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

  Widget _buildFullGoalMatrix(
    BuildContext context,
    WidgetRef ref,
    ProjectOverviewState state,
    Project project,
    DateTime normStart,
    DateTime normEnd,
  ) {
    final today = DayFinalizerService.getLogicalTrackingDate(DateTime.now());
    final isTrust = project.trackingMode == 'trust';
    final totalDays = project.targetDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: totalDays,
          itemBuilder: (ctx, i) {
            final dayNumber = i + 1;
            final dayDate = normStart.add(Duration(days: i));
            final isToday = dayDate == today;
            final isFuture = dayDate.isAfter(today);
            final isPaused = state.isDatePaused(dayDate);
            final record = state.getRecordForDate(dayDate);
            final isExplicitCompleted = record != null && record.status == 'completed';
            final isExplicitMissed = record != null && record.status == 'missed';

            final isCompleted = !isPaused && (isExplicitCompleted || (isTrust && !isFuture && !isExplicitMissed));
            final isMissed = !isPaused && isExplicitMissed;

            Color bgColor = Colors.grey.withValues(alpha: 0.1);
            Widget icon = Text('$dayNumber', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));

            if (isFuture) {
              bgColor = Colors.grey.withValues(alpha: 0.05);
            } else if (isPaused) {
              bgColor = Colors.amber.withValues(alpha: 0.15);
              icon = const Icon(Icons.pause_rounded, size: 14, color: Colors.amber);
            } else if (isMissed) {
              bgColor = Colors.red.withValues(alpha: 0.15);
              icon = const Icon(Icons.close_rounded, size: 14, color: Colors.red);
            } else if (isCompleted) {
              bgColor = Colors.green.withValues(alpha: 0.15);
              icon = const Icon(Icons.check_rounded, size: 14, color: Colors.green);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleDayTap(
                context,
                ref,
                project.id,
                dayDate,
                isToday: isToday,
                isFuture: isFuture,
                isBeforeStart: false,
                isPaused: isPaused,
                isTrust: isTrust,
                isCompleted: isCompleted,
                isMissed: isMissed,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('D$dayNumber', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 2),
                    icon,
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
    if (isTrust) {
      if (isMissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Option 1 Honesty Clause: Missed days are permanently locked.')),
        );
        return;
      }

      final shouldMarkMissed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark Day as Missed?'),
          content: Text(
            'In Trust Mode, you can change a completed past day (${DurationUtils.formatDate(date)}) to Missed.\n\n'
            'Warning: Once marked as Missed, it is permanently locked and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Missed'),
            ),
          ],
        ),
      );

      if (shouldMarkMissed == true) {
        await ref.read(projectOverviewControllerProvider(projectId).notifier).markDayAsMissed(date);
      }
    } else {
      // Strict Mode past days cannot be altered
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Strict Mode: Past days are permanently locked.')),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
