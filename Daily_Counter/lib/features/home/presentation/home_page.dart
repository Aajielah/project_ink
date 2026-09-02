import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';
import 'home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey)),
            const Text('Daily Counter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(homeControllerProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Quick Stats Overview Bar
                _buildStatsOverview(context, data),
                const SizedBox(height: 20),

                // 2. Due Today Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Due Today (${data.dueToday.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      DurationUtils.formatDate(DateTime.now()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Due Today Task Cards
                if (data.dueToday.isEmpty)
                  _buildAllCaughtUpCard(context)
                else
                  ...data.dueToday.map((p) => _buildDueTaskCard(context, ref, p)),

                const SizedBox(height: 24),

                // 4. Completed Today Section (if any)
                if (data.completedToday.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Completed Today (${data.completedToday.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...data.completedToday.map((p) => _buildCompletedTaskCard(context, p)),
                  const SizedBox(height: 20),
                ],

                // 5. Upcoming Goals Section (if any)
                if (data.upcoming.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Goals (${data.upcoming.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...data.upcoming.map((p) => _buildUpcomingTaskCard(context, p)),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading goals: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, HomeDashboardData data) {
    final runningCount = (data.totalActive - data.upcoming.length).clamp(0, 9999);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Due Today', '${data.dueToday.length}', Colors.orange),
            _buildStatDivider(),
            _buildStatColumn('Done Today', '${data.completedToday.length}', Colors.green),
            _buildStatDivider(),
            _buildStatColumn('Running', '$runningCount', Colors.blue),
            _buildStatDivider(),
            _buildStatColumn('Upcoming', '${data.upcoming.length}', Colors.teal),
            _buildStatDivider(),
            _buildStatColumn('Paused', '${data.totalPaused}', Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.2));
  }

  Widget _buildAllCaughtUpCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.celebration_rounded, size: 40, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'All Caught Up for Today! 🎉',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have completed all active commitments scheduled for today. Keep up the tremendous discipline!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueTaskCard(BuildContext context, WidgetRef ref, Project project) {
    final categoryColor = CategoryUtils.getColor(project.category, context);
    final progressPercent = (project.targetDays > 0)
        ? (project.completedDays / project.targetDays).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/overview/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CategoryUtils.getIcon(project.category), color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '${project.category} • ${project.trackingMode.toUpperCase()} MODE',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    tooltip: 'Check off for today',
                    onPressed: () {
                      ref.read(homeControllerProvider.notifier).completeProject(project.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${project.completedDays} of ${project.targetDays}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: categoryColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: categoryColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(BuildContext context, Project project) {
    final categoryColor = CategoryUtils.getColor(project.category, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.green.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(CategoryUtils.getIcon(project.category), color: categoryColor),
        title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Day ${project.completedDays} of ${project.targetDays} completed', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
        onTap: () => context.push('/overview/${project.id}'),
      ),
    );
  }

  Widget _buildUpcomingTaskCard(BuildContext context, Project project) {
    final categoryColor = CategoryUtils.getColor(project.category, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(CategoryUtils.getIcon(project.category), color: categoryColor),
        title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Starts on ${DurationUtils.formatDate(project.startDate)}', style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('UPCOMING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        onTap: () => context.push('/overview/${project.id}'),
      ),
    );
  }
}
