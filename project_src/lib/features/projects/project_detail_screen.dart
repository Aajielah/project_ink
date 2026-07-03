import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers.dart';
import '../../models/project.dart';
import '../../models/schedule.dart';
import '../../models/daily_log.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({required this.projectId, super.key});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _logController = TextEditingController();
  final _editTargetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logController.dispose();
    _editTargetController.dispose();
    super.dispose();
  }

  Future<void> _logWords(int planned) async {
    final text = _logController.text.trim();
    if (text.isEmpty) return;

    final actual = int.tryParse(text);
    if (actual == null || actual < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive word count.')),
      );
      return;
    }

    // Call logging service
    final loggingService = ref.read(loggingServiceProvider);
    try {
      await loggingService.logWords(
        projectId: widget.projectId,
        date: DateTime.now(),
        actualWords: actual,
      );
      
      _logController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Words logged successfully!')),
      );

      // Force UI updates
      ref.invalidate(projectsProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(homeQuoteProvider(widget.projectId));
      ref.invalidate(homeEncouragementProvider(widget.projectId));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updatePlan(ProjectModel project) async {
    final text = _editTargetController.text.trim();
    if (text.isEmpty) return;

    final newTarget = int.tryParse(text);
    if (newTarget == null || newTarget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target.')),
      );
      return;
    }

    final schedRepo = ref.read(scheduleRepositoryProvider);
    final scheds = await schedRepo.getSchedulesForProject(project.id);
    
    // Count how many rest days used in history
    int restDaysUsed = scheds.where((s) => s.locked && s.isRestDay).length;

    final schedService = ref.read(schedulingServiceProvider);
    final recalculated = schedService.recalculateFutureSchedule(
      existingSchedules: scheds,
      recalculateFromDate: DateTime.now(),
      newDailyTarget: newTarget,
      totalRemainingWords: project.remainingWords,
      fixedRestWeekdays: const [6, 7], // default Sat/Sun for recalculation
      restMode: project.restMode,
      allowedRestDaysBudget: project.allowedRestDays,
      restDaysUsed: restDaysUsed,
    );

    // Save recalculated schedule
    await schedRepo.deleteUnlockedFutureSchedules(project.id, DateTime.now());
    await schedRepo.insertSchedules(recalculated);

    // Update project target
    final updatedProject = project.copyWith(
      dailyWordTarget: newTarget,
      expectedFinishDate: recalculated.last.date,
      updatedAt: DateTime.now(),
    );
    await ref.read(projectRepositoryProvider).updateProject(updatedProject);

    _editTargetController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan updated successfully!')),
    );
    
    ref.invalidate(projectsProvider);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return projectsAsync.when(
      data: (projects) {
        final project = projects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => throw StateError('Project not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'This Week'),
                Tab(text: 'History'),
                Tab(text: 'Manage'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(project: project),
              _ThisWeekTab(
                project: project,
                logController: _logController,
                onLogSubmitted: _logWords,
              ),
              _HistoryTab(projectId: project.id),
              _ManageTab(
                project: project,
                editController: _editTargetController,
                onUpdatePlan: () => _updatePlan(project),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final ProjectModel project;

  const _OverviewTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quoteAsync = ref.watch(homeQuoteProvider(project.id));
    final progress = project.targetWords > 0 ? project.writtenWords / project.targetWords : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project Quote
          quoteAsync.when(
            data: (quote) => quote != null
                ? Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '"${quote.text}"\n— ${quote.author}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Main Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Project Streak',
                        value: '${project.projectStreak} days',
                        icon: Icons.local_fire_department,
                        color: theme.colorScheme.primary,
                      ),
                      _StatColumn(
                        label: 'Remaining',
                        value: '${project.remainingWords} words',
                        icon: Icons.hourglass_empty,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Target Goal',
                        value: '${project.targetWords} words',
                        icon: Icons.outlined_flag,
                        color: theme.colorScheme.primary,
                      ),
                      _StatColumn(
                        label: 'Estimated Finish',
                        value: DateFormat('MMM d, yyyy').format(project.expectedFinishDate),
                        icon: Icons.calendar_today,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: min(1.0, progress),
                    minHeight: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${project.writtenWords} words written'),
                      Text('${(progress * 100).toInt()}%'),
                    ],
                  ),
                  if (project.backlogWords > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          'Backlog: ${project.backlogWords} words missed.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ThisWeekTab extends ConsumerWidget {
  final ProjectModel project;
  final TextEditingController logController;
  final Function(int) onLogSubmitted;

  const _ThisWeekTab({
    required this.project,
    required this.logController,
    required this.onLogSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    // Calculate current week date bounds
    final weekdayOffset = today.weekday - 1; // days since Monday
    final monday = cleanToday.subtract(Duration(days: weekdayOffset));
    final sunday = monday.add(const Duration(days: 6));

    final schedRepo = ref.watch(scheduleRepositoryProvider);

    return FutureBuilder<List<ScheduleModel>>(
      future: schedRepo.getSchedulesForDateRange(project.id, monday, sunday),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekSchedules = snapshot.data!;
        ScheduleModel? todaySchedule;
        try {
          todaySchedule = weekSchedules.firstWhere((s) => s.date.day == cleanToday.day);
        } catch (_) {}

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Log words block
              if (project.status == ProjectStatus.active && todaySchedule != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Today\'s Progress',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todaySchedule.isRestDay
                              ? 'Today is scheduled as a REST DAY. Writing is optional!'
                              : 'Target for today: ${todaySchedule.plannedWords} words.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: logController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Words written today',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => onLogSubmitted(todaySchedule?.plannedWords ?? 0),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              ),
                              child: const Text('Log'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Weekly Calendar Targets
              Text(
                'This Week\'s Schedule',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weekSchedules.length,
                itemBuilder: (context, index) {
                  final s = weekSchedules[index];
                  final isToday = s.date.day == cleanToday.day;

                  return Card(
                    color: isToday ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                    shape: isToday
                        ? RoundedRectangleBorder(
                            side: BorderSide(color: theme.colorScheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: ListTile(
                      leading: Icon(
                        s.isRestDay
                            ? Icons.coffee
                            : s.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                        color: s.completed
                            ? theme.colorScheme.primary
                            : s.isRestDay
                                ? theme.colorScheme.outline
                                : null,
                      ),
                      title: Text(
                        DateFormat('EEEE, MMM d').format(s.date),
                        style: isToday ? const TextStyle(fontWeight: FontWeight.bold) : null,
                      ),
                      subtitle: Text(
                        s.isRestDay ? 'Rest Day' : '${s.plannedWords} words planned',
                      ),
                      trailing: isToday
                          ? Card(
                              elevation: 0,
                              color: theme.colorScheme.primary,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  'TODAY',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final String projectId;

  const _HistoryTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logRepo = ref.watch(dailyLogRepositoryProvider);
    final theme = Theme.of(context);

    return FutureBuilder<List<DailyLogModel>>(
      future: logRepo.getLogsForProject(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.reversed.toList();

        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No writing logs recorded yet. Start writing and log today!'),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final l = logs[index];
            final diff = l.actualWords - l.plannedWords;
            final isExcess = diff > 0;
            final isCompleted = l.completed;

            return Card(
              child: ListTile(
                leading: Icon(
                  isCompleted ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                title: Text(DateFormat('EEEE, MMM d, yyyy').format(l.date)),
                subtitle: Text(
                  'Wrote: ${l.actualWords} / ${l.plannedWords} planned',
                ),
                trailing: Text(
                  isExcess
                      ? '+${diff} words'
                      : diff < 0
                          ? '${diff} words'
                          : 'On target',
                  style: TextStyle(
                    color: isExcess
                        ? theme.colorScheme.primary
                        : diff < 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ManageTab extends ConsumerWidget {
  final ProjectModel project;
  final TextEditingController editController;
  final VoidCallback onUpdatePlan;

  const _ManageTab({
    required this.project,
    required this.editController,
    required this.onUpdatePlan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Target editing Card
        if (project.status == ProjectStatus.active)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust Writing Goal Target',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change your daily target for remaining days. Past locked days are preserved.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: editController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'New daily target',
                            hintText: 'Currently: ${project.dailyWordTarget}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onUpdatePlan,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        ),
                        child: const Text('Adjust'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Pause/Resume actions
        Card(
          child: Column(
            children: [
              if (project.status == ProjectStatus.active)
                ListTile(
                  leading: const Icon(Icons.pause),
                  title: const Text('Pause Project'),
                  subtitle: const Text('Temporarily freezes streaks and scheduled calendar days.'),
                  onTap: () async {
                    await ref.read(projectsProvider.notifier).pauseProject(project.id);
                  },
                ),
              if (project.status == ProjectStatus.paused)
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Resume Project'),
                  subtitle: const Text('Extend schedule and resume daily targets.'),
                  onTap: () async {
                    await ref.read(projectsProvider.notifier).resumeProject(project.id);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                title: Text(
                  'Delete Project',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Permanently deletes the project, history logs, and schedule.'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                          'Are you sure you want to permanently delete this writing project and all associated logs? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(projectsProvider.notifier).deleteProject(project.id);
                    context.pop(); // Go back to listings
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
