import 'package:flutter/material.dart';

void showHelpBottomSheet(BuildContext context, String topic) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
    ),
    builder: (context) {
      return _HelpBottomSheetContent(topic: topic);
    },
  );
}

class _HelpBottomSheetContent extends StatelessWidget {
  final String topic;

  const _HelpBottomSheetContent({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (topic == 'project_type') {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Writing Project Types',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Choose how you want to measure your progress and habits.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 32.0),

              // Fixed Goal Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag, color: theme.colorScheme.primary, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixed Goal Project',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Write according to a fixed plan with a set deadline and word count target. Missing a scheduled writing day without using a rest day will automatically create backlog that must be caught up later.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Ongoing Habit Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.all_inclusive, color: theme.colorScheme.secondary, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ongoing Habit Project',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'No strict deadline or total word count targets. Designed for diaries, daily writing exercises, journals, or permanent habits. Progress is measured by consistency and streak lengths rather than final completion.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (topic == 'rest_mode') {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Day Scheduling Modes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Configure how rest periods affect your writing goals.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 32.0),

              // Fixed Rest Days
              _buildRestModeDetail(
                context,
                icon: Icons.calendar_month,
                title: 'Fixed Rest Days',
                description: 'Set static repeating days of the week to rest (e.g. every Sunday). The system automatically schedules these days off, and they do not affect or consume any rest day budget.',
              ),
              const SizedBox(height: 24.0),

              // Flexible Rest Days
              _buildRestModeDetail(
                context,
                icon: Icons.edit_calendar,
                title: 'Flexible Rest Days',
                description: 'Best for writers who want full manual control. Whenever you decide to take a break, long-press today\'s writing mission to convert it to a Rest Day. Each action consumes one available Rest Day from your overall project budget. Once exhausted, skipped days create backlog.',
              ),
              const SizedBox(height: 24.0),

              // Adaptive Rest Days
              _buildRestModeDetail(
                context,
                icon: Icons.auto_mode,
                title: 'Adaptive Rest Days',
                description: 'Best for dynamic schedules. If you miss logging words before the grace period ends, Project Ink will automatically apply an available Adaptive Rest Day for you. Backlog is only created once your entire project rest budget is fully exhausted.',
              ),
              const SizedBox(height: 20.0),

              // Example Card for Adaptive Rest Days
              Card(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: theme.colorScheme.secondary, size: 20.0),
                          const SizedBox(width: 8.0),
                          Text(
                            'Adaptive Rollover Example',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '14-Day Project • 2 Adaptive Rest Days Budget\n\n'
                        'Day 5: No writing logged\n'
                        '↓\n'
                        'Adaptive Rest Day used automatically\n'
                        'Remaining: 1 Adaptive Rest Day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 13.0,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRestModeDetail(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24.0),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
