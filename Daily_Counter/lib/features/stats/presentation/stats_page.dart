import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/utils/category_utils.dart';

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final projects = await db.getAllProjects();

  int totalGoals = projects.length;
  int activeCount = projects.where((p) => p.status == 'active').toList().length;
  int completedCount = projects.where((p) => p.status == 'completed').toList().length;
  int pausedCount = projects.where((p) => p.status == 'paused').toList().length;

  int totalCompletedCheckIns = 0;
  int totalMissedCheckIns = 0;
  final Map<String, int> categoryCounts = {};

  for (var p in projects) {
    categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    final records = await db.getRecordsForProject(p.id);
    totalCompletedCheckIns += records.where((r) => r.status == 'completed').length;
    totalMissedCheckIns += records.where((r) => r.status == 'missed').length;
  }

  final totalLogged = totalCompletedCheckIns + totalMissedCheckIns;
  final consistencyScore = totalLogged > 0
      ? ((totalCompletedCheckIns / totalLogged) * 100).toInt()
      : 100;

  return {
    'totalGoals': totalGoals,
    'active': activeCount,
    'completed': completedCount,
    'paused': pausedCount,
    'completedCheckIns': totalCompletedCheckIns,
    'missedCheckIns': totalMissedCheckIns,
    'consistencyScore': consistencyScore,
    'categoryCounts': categoryCounts,
  };
});

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commitment Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(statsProvider),
            tooltip: 'Refresh stats',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final theme = Theme.of(context);
          final consistency = stats['consistencyScore'] as int;
          final categoryMap = stats['categoryCounts'] as Map<String, int>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Consistency Score Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Overall Consistency Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        '$consistency%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: consistency >= 80 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        consistency >= 80
                            ? 'Excellent discipline! You are honoring your daily promises.'
                            : 'Every day is a fresh opportunity to build momentum.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Grid
              Text('Summary Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Goals', '${stats['totalGoals']}', Icons.flag_rounded, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Completed', '${stats['completed']}', Icons.emoji_events_rounded, Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Active Running', '${stats['active']}', Icons.play_arrow_rounded, Colors.indigo)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('On Hold / Paused', '${stats['paused']}', Icons.pause_circle_rounded, Colors.amber)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Days Done', '${stats['completedCheckIns']}', Icons.check_circle_rounded, Colors.teal)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Days Missed', '${stats['missedCheckIns']}', Icons.close_rounded, Colors.red)),
                ],
              ),
              const SizedBox(height: 24),

              // Category Distribution
              if (categoryMap.isNotEmpty) ...[
                Text('Category Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryMap.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final category = categoryMap.keys.elementAt(index);
                      final count = categoryMap[category]!;
                      final color = CategoryUtils.getColor(category, context);

                      return ListTile(
                        leading: Icon(CategoryUtils.getIcon(category), color: color),
                        title: Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count ${count == 1 ? 'goal' : 'goals'}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading analytics: $err')),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
