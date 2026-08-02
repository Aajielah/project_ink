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
                description: 'Best for writers who want full manual control. Whenever you decide to take a break, long-press today\'s writing mission to convert it to a Rest Day. Each action consumes one available Rest Day from your overall project budget. Once exhausted, skipped days create backlog.\n\nFlexible Rest Days are earned gradually each week.\n\nExample:\nIf your project allows 8 rest days over 4 weeks, you may receive 2 days each week.\n\nUnused rest days carry over into the following weeks, allowing you to save them for later.',
              ),
              const SizedBox(height: 24.0),

              // Adaptive Rest Days
              _buildRestModeDetail(
                context,
                icon: Icons.auto_mode,
                title: 'Adaptive Rest Days',
                description: 'Best for dynamic schedules. If you miss logging words before the grace period ends, Project Ink will automatically apply an available Adaptive Rest Day for you. Backlog is only created once your entire project rest budget is fully exhausted.\n\nAdaptive Rest Days are also earned gradually.\n\nHowever, they expire at the end of the week.\n\nIf you don\'t use them, they are lost and cannot be carried forward.\n\nThis encourages consistent writing while still allowing occasional recovery.',
              ),
              const SizedBox(height: 24.0),

              // Sprint Mode
              _buildRestModeDetail(
                context,
                icon: Icons.bolt,
                title: 'Sprint Mode',
                description: 'Sprint Mode is intended for short writing challenges.\n\n• Available only for projects lasting 10 days or fewer.\n• No rest days are allowed.\n• Every scheduled writing day is mandatory.\n• Any missed day immediately becomes backlog.\n\nChoose this mode only when you\'re committed to maintaining a continuous writing streak until the project is finished.',
              ),
            ],
          ),
        ),
      );
    } else if (topic == 'ongoing_style') {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Writing Schedule Styles',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Select how you want to schedule your ongoing writing habit.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 32.0),

              // Daily Mode
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Write every single day. There are no scheduled recovery days. Ideal for building a strict daily writing habit.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Rhythm Mode
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.repeat, color: theme.colorScheme.secondary, size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rhythm Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Write every other day. Recovery days are automatically scheduled and alternate with writing days. No rest-day management is required, helping you maintain consistency while preventing burnout.',
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
