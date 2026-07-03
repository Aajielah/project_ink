import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/project.dart';
import '../../models/schedule.dart';
import '../../models/daily_log.dart';
import '../../models/quote.dart';
import '../projects/widgets/book_cover_widget.dart';

class TodayWritingTask {
  final ProjectModel project;
  final ScheduleModel schedule;
  final DailyLogModel? log;

  const TodayWritingTask({
    required this.project,
    required this.schedule,
    this.log,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<List<TodayWritingTask>> _fetchTodayTasks(List<ProjectModel> activeProjects) async {
    final schedRepo = ref.read(scheduleRepositoryProvider);
    final logRepo = ref.read(dailyLogRepositoryProvider);
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    final List<TodayWritingTask> tasks = [];
    for (final p in activeProjects) {
      final sched = await schedRepo.getScheduleForDate(p.id, cleanToday);
      if (sched != null) {
        final log = await logRepo.getLogForDate(p.id, cleanToday);
        tasks.add(TodayWritingTask(project: p, schedule: sched, log: log));
      }
    }
    return tasks;
  }

  void _triggerQuickLog(List<TodayWritingTask> tasks) {
    // Filter tasks that require writing today (exclude rest days)
    final writingTasks = tasks.where((t) => !t.schedule.isRestDay).toList();

    if (writingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No writing tasks scheduled for today! Enjoy your rest day.')),
      );
      return;
    }

    if (writingTasks.length == 1) {
      // Auto-assign directly to the single active task
      _showSingleLogDialog(writingTasks.first);
    } else {
      // Multiple active tasks: show Split Log options dialog
      _showSplitLogDialog(writingTasks);
    }
  }

  void _showSingleLogDialog(TodayWritingTask task) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Words for "${task.project.name}"'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Words Written Today',
              hintText: 'e.g. 500',
              suffixText: 'words',
              helperText: 'Target today: ${task.schedule.plannedWords} words',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final words = int.tryParse(text) ?? 0;
                if (words <= 0) return;

                Navigator.pop(context);
                await _submitLog(task.project.id, words);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _showSplitLogDialog(List<TodayWritingTask> tasks) {
    final totalController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Global Quick Log'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: totalController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Total Words Written',
                        hintText: 'Enter total words written across all books',
                        suffixText: 'words',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose Distribution Strategy:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      title: const Text('⚖️ Even Split'),
                      subtitle: const Text('Distribute words equally among all active books today.'),
                      onTap: () {
                        final val = int.tryParse(totalController.text) ?? 0;
                        if (val <= 0) return;
                        Navigator.pop(context);
                        _applyEvenSplit(tasks, val);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      title: const Text('📊 Proportional Split'),
                      subtitle: const Text('Distribute words based on today\'s targets.'),
                      onTap: () {
                        final val = int.tryParse(totalController.text) ?? 0;
                        if (val <= 0) return;
                        Navigator.pop(context);
                        _applyProportionalSplit(tasks, val);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      title: const Text('🧠 Smart Split'),
                      subtitle: const Text('Fills backlogs first, then targets.'),
                      onTap: () {
                        final val = int.tryParse(totalController.text) ?? 0;
                        if (val <= 0) return;
                        Navigator.pop(context);
                        _applySmartSplit(tasks, val);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      title: const Text('✍️ Manual Allocation'),
                      subtitle: const Text('Enter custom words for each project individually.'),
                      onTap: () {
                        Navigator.pop(context);
                        _showManualAllocationDialog(tasks);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManualAllocationDialog(List<TodayWritingTask> tasks) {
    final controllers = {for (var t in tasks) t.project.id: TextEditingController()};

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Word Allocation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tasks.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: controllers[t.project.id],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.project.name,
                      suffixText: 'words',
                      helperText: 'Target today: ${t.schedule.plannedWords} words',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Submit logs for each project
                for (final t in tasks) {
                  final text = controllers[t.project.id]!.text.trim();
                  if (text.isNotEmpty) {
                    final words = int.tryParse(text) ?? 0;
                    if (words > 0) {
                      await ref.read(loggingServiceProvider).logProgress(t.project.id, words);
                    }
                  }
                }
                
                _refreshAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manual logs saved successfully!')),
                );
              },
              child: const Text('Save All'),
            )
          ],
        );
      },
    );
  }

  Future<void> _submitLog(String projectId, int words) async {
    try {
      await ref.read(loggingServiceProvider).logProgress(projectId, words);
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully logged $words words!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log words: $e')),
      );
    }
  }

  void _applyEvenSplit(List<TodayWritingTask> tasks, int totalWords) async {
    final count = tasks.length;
    final splitWords = totalWords ~/ count;
    final remainder = totalWords % count;

    for (int i = 0; i < count; i++) {
      final task = tasks[i];
      final wordsToLog = i == 0 ? splitWords + remainder : splitWords;
      await ref.read(loggingServiceProvider).logProgress(task.project.id, wordsToLog);
    }
    
    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evenly distributed $totalWords words across $count projects!')),
    );
  }

  void _applyProportionalSplit(List<TodayWritingTask> tasks, int totalWords) async {
    final totalPlanned = tasks.fold<int>(0, (sum, t) => sum + t.schedule.plannedWords);
    if (totalPlanned <= 0) {
      _applyEvenSplit(tasks, totalWords);
      return;
    }

    int remainingToLog = totalWords;
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      int wordsToLog = 0;
      if (i == tasks.length - 1) {
        wordsToLog = remainingToLog;
      } else {
        wordsToLog = (task.schedule.plannedWords / totalPlanned * totalWords).round();
        remainingToLog -= wordsToLog;
      }
      if (wordsToLog > 0) {
        await ref.read(loggingServiceProvider).logProgress(task.project.id, wordsToLog);
      }
    }

    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Distributed $totalWords words proportionally based on targets!')),
    );
  }

  void _applySmartSplit(List<TodayWritingTask> tasks, int totalWords) async {
    // Heuristic:
    // 1. Allocate words to satisfy existing backlog first
    // 2. Allocate remaining words to satisfy today's targets
    // 3. Allocate any remaining overflow proportionally
    int remainingWords = totalWords;
    final Map<String, int> allocations = {for (var t in tasks) t.project.id: 0};

    // First: fill backlogs
    for (final t in tasks) {
      if (remainingWords <= 0) break;
      final backlog = t.project.backlogWords;
      if (backlog > 0) {
        final fill = min(backlog, remainingWords);
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + fill;
        remainingWords -= fill;
      }
    }

    // Second: satisfy today's target
    for (final t in tasks) {
      if (remainingWords <= 0) break;
      final target = t.schedule.plannedWords;
      if (target > 0) {
        final fill = min(target, remainingWords);
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + fill;
        remainingWords -= fill;
      }
    }

    // Third: split any overflow evenly
    if (remainingWords > 0) {
      final split = remainingWords ~/ tasks.length;
      final rem = remainingWords % tasks.length;
      for (int i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        final add = i == 0 ? split + rem : split;
        allocations[t.project.id] = (allocations[t.project.id] ?? 0) + add;
      }
    }

    // Submit all logs
    for (final entry in allocations.entries) {
      if (entry.value > 0) {
        await ref.read(loggingServiceProvider).logProgress(entry.key, entry.value);
      }
    }

    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Smart split completed! Backlogs filled first.')),
    );
  }

  void _refreshAll() {
    ref.invalidate(projectsProvider);
    ref.invalidate(statisticsProvider);
    ref.invalidate(homeQuoteProvider(null));
    ref.invalidate(homeEncouragementProvider(null));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final statsAsync = ref.watch(statisticsProvider);
    final quoteAsync = ref.watch(homeQuoteProvider(null));
    final encouragementAsync = ref.watch(homeEncouragementProvider(null));

    final String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Mission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Streak row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  statsAsync.when(
                    data: (stats) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '${stats.currentGlobalStreak} DAYS',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Motivational Quote Card
              quoteAsync.when(
                data: (quote) => quote != null ? _QuoteCard(quote: quote) : const SizedBox(),
                loading: () => const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Today's Missions List
              projectsAsync.when(
                data: (projects) {
                  final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();
                  if (activeProjects.isEmpty) {
                    return _NoActiveProjectsCard();
                  }

                  return FutureBuilder<List<TodayWritingTask>>(
                    future: _fetchTodayTasks(activeProjects),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final todayTasks = snapshot.data!;
                      if (todayTasks.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No projects scheduled for today! Take a well-deserved break.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      // Calculate today's totals
                      int totalPlannedToday = 0;
                      int totalLoggedToday = 0;
                      for (final t in todayTasks) {
                        if (!t.schedule.isRestDay) {
                          totalPlannedToday += t.schedule.plannedWords;
                          totalLoggedToday += t.log?.actualWords ?? 0;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TODAY\'S MISSIONS',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (totalPlannedToday > 0)
                                FilledButton.icon(
                                  onPressed: () => _triggerQuickLog(todayTasks),
                                  icon: const Icon(Icons.bolt, size: 16),
                                  label: const Text('Quick Log'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: todayTasks.length,
                            separatorBuilder: (c, i) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = todayTasks[index];
                              final isRest = task.schedule.isRestDay;
                              final logged = task.log?.actualWords ?? 0;
                              final target = task.schedule.plannedWords;
                              final progress = target > 0 ? min(1.0, logged / target) : 0.0;

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      // Miniature Book Cover Widget
                                      BookCoverWidget(
                                        title: task.project.name,
                                        coverImagePath: task.project.coverImagePath,
                                        coverType: task.project.coverType,
                                        width: 60,
                                        height: 80,
                                        borderRadius: 6.0,
                                        showTitle: false,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.project.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (isRest)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.secondaryContainer,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '🏝 REST DAY',
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: theme.colorScheme.onSecondaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            else ...[
                                              Text(
                                                '$logged / $target words',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                      if (!isRest) ...[
                                        const SizedBox(width: 8),
                                        IconButton.filledTonal(
                                          onPressed: () => _showSingleLogDialog(task),
                                          icon: const Icon(Icons.add),
                                          tooltip: 'Log words',
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Daily Combined Total summary
                          if (totalPlannedToday > 0)
                            Card(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: theme.colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Today\'s Combined Total:',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$totalLoggedToday / $totalPlannedToday words',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              // Contextual system encouragement section
              Text(
                'Personal Insights & Progress',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              encouragementAsync.when(
                data: (messages) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: messages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              messages[index].startsWith('🔥')
                                  ? Icons.local_fire_department
                                  : messages[index].startsWith('🏁')
                                      ? Icons.flag
                                      : messages[index].startsWith('🌓')
                                          ? Icons.star_half
                                          : messages[index].startsWith('💾')
                                              ? Icons.save
                                              : Icons.info_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                messages[index],
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteModel quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${quote.text}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${quote.author}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Text(
                  quote.category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontSize: 8.0,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveProjectsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.edit_note, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No Active Writing Projects',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new project to start scheduling your daily targets and writing streak!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/projects/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}
