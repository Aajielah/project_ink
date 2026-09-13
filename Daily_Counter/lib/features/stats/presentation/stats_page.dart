import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/utils/category_utils.dart';
import '../../../shared/models/project.dart';

final statsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final projects = await db.getAllProjects();

  int totalGoals = projects.length;
  int activeCount = projects.where((p) => p.status == 'active').length;
  int completedCount = projects.where((p) => p.status == 'completed').length;
  int pausedCount = projects.where((p) => p.status == 'paused').length;

  int totalCompletedCheckIns = 0;
  int totalMissedCheckIns = 0;
  final Set<String> activeCalendarDates = {};
  final Map<String, List<Project>> categoryProjects = {};

  for (var p in projects) {
    categoryProjects.putIfAbsent(p.category, () => []).add(p);
    final records = await db.getRecordsForProject(p.id);
    for (var r in records) {
      if (r.status == 'completed') {
        totalCompletedCheckIns++;
        activeCalendarDates.add('${r.date.year}-${r.date.month}-${r.date.day}');
      } else if (r.status == 'missed') {
        totalMissedCheckIns++;
      }
    }
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
    'daysActive': activeCalendarDates.length,
    'consistencyScore': consistencyScore,
    'categoryProjects': categoryProjects,
  };
});

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(statsProvider));
  }

  @override
  Widget build(BuildContext context) {
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
          final daysActive = stats['daysActive'] as int;
          final categoryProjectsMap = stats['categoryProjects'] as Map<String, List<Project>>;

          return ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$daysActive Calendar Days Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
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

              // Summary Metrics Grid (Cleaned - Check-Ins Done/Missed removed)
              Text('Summary Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Total Goals', '${stats['totalGoals']}', Icons.flag_rounded, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Completed Goals', '${stats['completed']}', Icons.emoji_events_rounded, Colors.green)),
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
              const SizedBox(height: 24),

              // Category Breakdown with Expandable Task View
              if (categoryProjectsMap.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Category Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Text('Tap to view tasks', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                ...categoryProjectsMap.entries.map((entry) {
                  final category = entry.key;
                  final projectList = entry.value;
                  final color = CategoryUtils.getColor(category, context);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: color.withValues(alpha: 0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CategoryUtils.getIcon(category), color: color, size: 20),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${projectList.length} ${projectList.length == 1 ? 'goal' : 'goals'}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                          ),
                        ),
                        children: [
                          const Divider(height: 1),
                          ...projectList.map((p) {
                            final progress = (p.targetDays > 0)
                                ? (p.completedDays / p.targetDays).clamp(0.0, 1.0)
                                : 0.0;

                            return InkWell(
                              onTap: () => context.push('/overview/${p.id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Day ${p.completedDays} / ${p.targetDays} (${(progress * 100).toInt()}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation(color),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading stats: $err')),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
