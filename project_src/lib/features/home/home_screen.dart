import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers.dart';
import '../../models/quote.dart';
import '../../models/project.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final statsAsync = ref.watch(statisticsProvider);
    final quoteAsync = ref.watch(homeQuoteProvider(null));
    final encouragementAsync = ref.watch(homeEncouragementProvider(null));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Ink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectsProvider);
          ref.invalidate(statisticsProvider);
          ref.invalidate(homeQuoteProvider(null));
          ref.invalidate(homeEncouragementProvider(null));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and global streak row
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
                        'Ready to log some words today?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  statsAsync.when(
                    data: (stats) => Tooltip(
                      message: 'Global streak of completed daily writing targets.',
                      child: Card(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${stats.currentGlobalStreak} days',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Motivational Quote Card
              quoteAsync.when(
                data: (quote) => quote != null ? _QuoteCard(quote: quote) : const SizedBox(),
                loading: () => const Card(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Could not load quote: $err'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today's Combined Progress Card
              projectsAsync.when(
                data: (projects) {
                  final activeProjects = projects.where((p) => p.status == ProjectStatus.active).toList();
                  if (activeProjects.isEmpty) {
                    return _NoActiveProjectsCard();
                  }

                  return _DailyProgressCard(activeProjects: activeProjects);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading projects: $err'),
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
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${quote.text}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '— ${quote.author}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      quote.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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

class _DailyProgressCard extends ConsumerWidget {
  final List<ProjectModel> activeProjects;

  const _DailyProgressCard({required this.activeProjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Sum today's planned and logged words for all active projects
    // Wait, since fetching schedule is async, we can build a widget that aggregates them.
    // Or we can let it query schedules dynamically. Let's do a simple FutureBuilder.
    return FutureBuilder<Map<String, int>>(
      future: _calculateTodayProgress(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
        }

        final data = snapshot.data!;
        final planned = data['planned']!;
        final logged = data['logged']!;
        final double progress = planned > 0 ? min(1.0, logged / planned) : 0.0;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Combined Progress',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$logged / $planned words written',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _calculateTodayProgress(WidgetRef ref) async {
    final schedRepo = ref.read(scheduleRepositoryProvider);
    final logRepo = ref.read(dailyLogRepositoryProvider);
    
    int totalPlanned = 0;
    int totalLogged = 0;
    
    final today = DateTime.now();
    final cleanToday = DateTime(today.year, today.month, today.day);

    for (final project in activeProjects) {
      final schedule = await schedRepo.getScheduleForDate(project.id, cleanToday);
      if (schedule != null) {
        totalPlanned += schedule.plannedWords;
      }
      final log = await logRepo.getLogForDate(project.id, cleanToday);
      if (log != null) {
        totalLogged += log.actualWords;
      }
    }

    return {'planned': totalPlanned, 'logged': totalLogged};
  }
}
