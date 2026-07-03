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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logController.dispose();
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

  Future<void> _showEditProjectDialog(ProjectModel project) async {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description ?? '');
    final targetWordsController = TextEditingController(text: project.targetWords.toString());
    final dailyTargetController = TextEditingController(text: project.dailyWordTarget.toString());
    
    RestMode editRestMode = project.restMode;
    int editAllowedRestDays = project.allowedRestDays;
    
    final schedRepo = ref.read(scheduleRepositoryProvider);
    final existingScheds = await schedRepo.getSchedulesForProject(project.id);
    
    final List<int> editFixedRestDays = [];
    if (project.restMode == RestMode.fixed) {
      for (final s in existingScheds) {
        if (s.isRestDay) {
          final wd = s.date.weekday;
          if (!editFixedRestDays.contains(wd)) {
            editFixedRestDays.add(wd);
          }
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Project Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetWordsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Target Words', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dailyTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Word Target', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<RestMode>(
                      value: editRestMode,
                      decoration: const InputDecoration(labelText: 'Rest Mode', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: RestMode.fixed, child: Text('Fixed (Weekly Days)')),
                        DropdownMenuItem(value: RestMode.flexible, child: Text('Flexible (Budget)')),
                        DropdownMenuItem(value: RestMode.random, child: Text('Random')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            editRestMode = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (editRestMode == RestMode.fixed) ...[
                      const Text('Choose Rest Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          FilterChip(
                            label: const Text('Mon'),
                            selected: editFixedRestDays.contains(1),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(1) : editFixedRestDays.remove(1)),
                          ),
                          FilterChip(
                            label: const Text('Tue'),
                            selected: editFixedRestDays.contains(2),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(2) : editFixedRestDays.remove(2)),
                          ),
                          FilterChip(
                            label: const Text('Wed'),
                            selected: editFixedRestDays.contains(3),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(3) : editFixedRestDays.remove(3)),
                          ),
                          FilterChip(
                            label: const Text('Thu'),
                            selected: editFixedRestDays.contains(4),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(4) : editFixedRestDays.remove(4)),
                          ),
                          FilterChip(
                            label: const Text('Fri'),
                            selected: editFixedRestDays.contains(5),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(5) : editFixedRestDays.remove(5)),
                          ),
                          FilterChip(
                            label: const Text('Sat'),
                            selected: editFixedRestDays.contains(6),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(6) : editFixedRestDays.remove(6)),
                          ),
                          FilterChip(
                            label: const Text('Sun'),
                            selected: editFixedRestDays.contains(7),
                            onSelected: (sel) => setDialogState(() => sel ? editFixedRestDays.add(7) : editFixedRestDays.remove(7)),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextFormField(
                        initialValue: editAllowedRestDays.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Rest Days Allowed Per Week',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 0 && parsed <= 6) {
                            editAllowedRestDays = parsed;
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    final targetWords = int.tryParse(targetWordsController.text) ?? project.targetWords;
                    final dailyTarget = int.tryParse(dailyTargetController.text) ?? project.dailyWordTarget;

                    if (name.isEmpty || targetWords <= project.writtenWords || dailyTarget <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid input fields. Target words must exceed written words.')),
                      );
                      return;
                    }

                    final today = DateTime.now();
                    final cleanToday = DateTime(today.year, today.month, today.day);
                    final restDaysUsed = existingScheds.where((s) => s.locked && s.isRestDay).length;

                    final remainingWords = targetWords - project.writtenWords;

                    final schedService = ref.read(schedulingServiceProvider);
                    final recalculated = schedService.recalculateFutureSchedule(
                      existingSchedules: existingScheds,
                      recalculateFromDate: cleanToday,
                      newDailyTarget: dailyTarget,
                      totalRemainingWords: remainingWords,
                      fixedRestWeekdays: editFixedRestDays,
                      restMode: editRestMode,
                      allowedRestDaysBudget: editAllowedRestDays,
                      restDaysUsed: restDaysUsed,
                    );

                    await schedRepo.deleteUnlockedFutureSchedules(project.id, cleanToday);
                    await schedRepo.insertSchedules(recalculated);

                    final updated = project.copyWith(
                      name: name,
                      description: desc.isNotEmpty ? desc : null,
                      targetWords: targetWords,
                      dailyWordTarget: dailyTarget,
                      restMode: editRestMode,
                      allowedRestDays: editAllowedRestDays,
                      expectedFinishDate: recalculated.isNotEmpty ? recalculated.last.date : project.expectedFinishDate,
                      remainingWords: remainingWords,
                      updatedAt: DateTime.now(),
                    );

                    await ref.read(projectsProvider.notifier).updateProject(updated);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Project settings updated and schedule recalculated!')),
                      );
                    }
                    _refreshAll();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _refreshAll() {
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
                onEditConfiguration: _showEditProjectDialog,
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
  final Function(ProjectModel) onEditConfiguration;

  const _ManageTab({
    required this.project,
    required this.onEditConfiguration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Configuration edit panel
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Project Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adjust writing goals, timeline, or rest day setups. Project Ink will recalculate future days while preserving your logs.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => onEditConfiguration(project),
                  icon: const Icon(Icons.settings),
                  label: const Text('Edit Project Configuration'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
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

