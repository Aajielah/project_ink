import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../shared/models/project.dart';

final allProjectsProvider = FutureProvider.autoDispose<List<Project>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllProjects();
});

class ProjectsHubPage extends ConsumerStatefulWidget {
  const ProjectsHubPage({super.key});

  @override
  ConsumerState<ProjectsHubPage> createState() => _ProjectsHubPageState();
}

class _ProjectsHubPageState extends ConsumerState<ProjectsHubPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(allProjectsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final today = DurationUtils.normalizeDate(DateTime.now());

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Goals & Commitments', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(allProjectsProvider),
              tooltip: 'Refresh list',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Running (Active)'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Paused'),
              Tab(text: 'Completed'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: projectsAsync.when(
          data: (projects) {
            final running = projects.where((p) => p.status == 'active' && !DurationUtils.normalizeDate(p.startDate).isAfter(today)).toList();
            final upcoming = projects.where((p) => p.status == 'active' && DurationUtils.normalizeDate(p.startDate).isAfter(today)).toList();
            final paused = projects.where((p) => p.status == 'paused').toList();
            final completed = projects.where((p) => p.status == 'completed').toList();
            final archived = projects.where((p) => p.status == 'archived').toList();

            return TabBarView(
              children: [
                _buildProjectList(context, ref, running, 'No currently running goals. Tap + to start one!'),
                _buildProjectList(context, ref, upcoming, 'No upcoming scheduled goals.'),
                _buildProjectList(context, ref, paused, 'No paused goals currently on hold.'),
                _buildProjectList(context, ref, completed, 'No completed goals yet. Keep going!'),
                _buildProjectList(context, ref, archived, 'No archived goals.'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading goals: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/create');
            ref.invalidate(allProjectsProvider);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Goal'),
        ),
      ),
    );
  }

  Widget _buildProjectList(
    BuildContext context,
    WidgetRef ref,
    List<Project> list,
    String emptyMessage,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final p = list[index];
        return _buildGoalCard(context, ref, p);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Project project) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getColor(project.category, context);
    final progressPercent = (project.targetDays > 0)
        ? (project.completedDays / project.targetDays).clamp(0.0, 1.0)
        : 0.0;
    final isUpcoming = DurationUtils.normalizeDate(project.startDate)
        .isAfter(DurationUtils.normalizeDate(DateTime.now()));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await context.push('/overview/${project.id}');
          ref.invalidate(allProjectsProvider);
        },
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
                    child: Icon(CategoryUtils.getIcon(project.category), color: categoryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.category} • ${project.trackingMode.toUpperCase()} MODE',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (isUpcoming && project.status == 'active')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('UPCOMING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                    )
                  else
                    _buildStatusChip(project.status),
                ],
              ),
              if (project.motivation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${project.motivation}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${project.completedDays} / ${project.targetDays}',
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUpcoming
                        ? 'Starts: ${DurationUtils.formatDate(project.startDate)}'
                        : 'End: ${DurationUtils.formatDate(project.endDate)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('History', style: TextStyle(fontSize: 12)),
                        onPressed: () => context.push('/history/${project.id}'),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          await context.push('/edit/${project.id}');
                          ref.invalidate(allProjectsProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.blue.withValues(alpha: 0.15);
    Color fg = Colors.blue;

    if (status == 'paused') {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amber.shade800;
    } else if (status == 'completed') {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
    } else if (status == 'archived') {
      bg = Colors.grey.withValues(alpha: 0.15);
      fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
