import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import '../../shared/cover_matching_helper.dart';
import 'package:intl/intl.dart';

import '../../shared/providers.dart';
import '../../models/project.dart';
import 'widgets/book_cover_widget.dart';

class ProjectGroup {
  final String groupId;
  final List<ProjectModel> projects;

  ProjectGroup({required this.groupId, required this.projects});

  ProjectModel? get runningProject {
    try {
      return projects.firstWhere(
        (p) =>
            p.status == ProjectStatus.active ||
            p.status == ProjectStatus.paused ||
            p.status == ProjectStatus.frozen ||
            p.status == ProjectStatus.upcoming,
      );
    } catch (_) {
      return null;
    }
  }

  List<ProjectModel> get completedProjects =>
      projects.where((p) => p.status == ProjectStatus.completed).toList()
        ..sort((a, b) => (b.actualFinishDate ?? b.updatedAt).compareTo(a.actualFinishDate ?? a.updatedAt));

  bool get hasCompletedRuns => completedProjects.isNotEmpty;

  bool get hasMultipleRuns => (runningProject != null && completedProjects.isNotEmpty) || completedProjects.length > 1;

  ProjectModel get primaryProject => runningProject ?? (completedProjects.isNotEmpty ? completedProjects.first : projects.first);

  int get totalWordsAllRuns => projects.fold<int>(0, (sum, p) => sum + p.writtenWords);
}

List<ProjectGroup> groupProjectsList(List<ProjectModel> projects) {
  final Map<String, List<ProjectModel>> map = {};
  for (final p in projects) {
    final gid = p.groupId ?? p.id;
    map.putIfAbsent(gid, () => []).add(p);
  }
  return map.entries.map((e) => ProjectGroup(groupId: e.key, projects: e.value)).toList();
}

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Projects'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Paused / Frozen'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: projectsAsync.when(
          data: (projects) {
            final allGroups = groupProjectsList(projects);
            final active = allGroups.where((g) => g.runningProject?.status == ProjectStatus.active).toList();
            final inactive = allGroups.where((g) => g.runningProject != null && (g.runningProject!.status == ProjectStatus.paused || g.runningProject!.status == ProjectStatus.frozen || g.runningProject!.status == ProjectStatus.upcoming)).toList();
            final completed = allGroups.where((g) => g.runningProject == null && g.hasCompletedRuns).toList();

            return TabBarView(
              children: [
                _ProjectGroupList(groups: active, emptyMessage: 'No active projects. Start a new writing project today!'),
                _ProjectGroupList(groups: inactive, emptyMessage: 'No paused or frozen projects.'),
                _ProjectGroupList(groups: completed, emptyMessage: 'No completed projects yet. Keep writing!'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading projects: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/projects/create'),
          icon: const Icon(Icons.add),
          label: const Text('New Project'),
        ),
      ),
    );
  }
}

class _ProjectGroupList extends ConsumerWidget {
  final List<ProjectGroup> groups;
  final String emptyMessage;

  const _ProjectGroupList({super.key, required this.groups, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _ProjectGroupCard(
          key: ValueKey(group.groupId),
          index: index,
          group: group,
        );
      },
      onReorder: (oldIndex, newIndex) async {
        final tabGroups = List<ProjectGroup>.from(groups);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = tabGroups.removeAt(oldIndex);
        tabGroups.insert(newIndex, item);

        // Flatten the reordered groups into individual projects preserving group order
        final allProjects = ref.read(projectsProvider).value ?? [];
        final reorderedProjectIds = tabGroups.expand((g) => g.projects.map((p) => p.id)).toSet();

        final reorderedList = <ProjectModel>[];
        for (final g in tabGroups) {
          reorderedList.addAll(g.projects);
        }
        for (final p in allProjects) {
          if (!reorderedProjectIds.contains(p.id)) {
            reorderedList.add(p);
          }
        }

        await ref.read(projectsProvider.notifier).reorderProjects(reorderedList);
      },
    );
  }
}

class _ProjectGroupCard extends ConsumerWidget {
  final int index;
  final ProjectGroup group;

  const _ProjectGroupCard({super.key, required this.index, required this.group});

  Future<void> _pickCustomCover(BuildContext context, WidgetRef ref, ProjectModel project) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final pickedPath = pickedFile.path;
        final appDir = await getApplicationDocumentsDirectory();
        
        final existingPath = await findExistingMatchingCover(File(pickedPath), appDir);
        
        String finalPath;
        if (existingPath != null) {
          finalPath = existingPath;
        } else {
          final extensionName = p.extension(pickedPath);
          final fileName = 'cover_${project.id}_${DateTime.now().millisecondsSinceEpoch}$extensionName';
          final savedFile = await File(pickedPath).copy('${appDir.path}/$fileName');
          finalPath = savedFile.path;
        }
        
        final updated = project.copyWith(
          coverType: 'uploaded',
          coverImagePath: finalPath,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(projectsProvider.notifier).updateProject(updated);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book cover updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cover image: $e')),
        );
      }
    }
  }

  Future<void> _rollRandomCover(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final random = Random();
    final chosen = defaultCovers[random.nextInt(defaultCovers.length)];
    
    final updated = project.copyWith(
      coverType: 'default',
      coverImagePath: chosen.id,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(projectsProvider.notifier).updateProject(updated);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Random cover selected!')),
      );
    }
  }

  Future<void> _removeCover(BuildContext context, WidgetRef ref, ProjectModel project) async {
    final updated = project.copyWith(
      coverType: null,
      coverImagePath: null,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(projectsProvider.notifier).updateProject(updated);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover removed.')),
      );
    }
  }

  void _showCoverActionSheet(BuildContext context, WidgetRef ref, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                child: Text(
                  'Manage Cover for "${project.name}"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('📷 Upload Custom Cover'),
                onTap: () {
                  Navigator.pop(context);
                  _pickCustomCover(context, ref, project);
                },
              ),
              ListTile(
                leading: const Icon(Icons.casino),
                title: const Text('🖼 Choose Random Default Cover'),
                onTap: () {
                  Navigator.pop(context);
                  _rollRandomCover(context, ref, project);
                },
              ),
              if (project.coverType != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('❌ Remove Cover', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeCover(context, ref, project);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showGroupRunsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final primary = group.primaryProject;
        final running = group.runningProject;
        final completed = group.completedProjects;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCoverWidget(
                        title: primary.name,
                        coverImagePath: primary.coverImagePath,
                        coverType: primary.coverType,
                        width: 60,
                        height: 80,
                        borderRadius: 6.0,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primary.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NumberFormat('#,###').format(group.totalWordsAllRuns)} words total across all runs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${running != null ? "1 Active Run • " : ""}${completed.length} Completed Run${completed.length > 1 ? "s" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // SECTION 1: RUNNING PROJECT (if any)
                  if (running != null) ...[
                    Row(
                      children: [
                        Icon(Icons.bolt, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CURRENT RUNNING PROJECT',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/projects/${running.id}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      running.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusChip(status: running.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                running.projectType == ProjectType.ongoing
                                    ? '${NumberFormat('#,###').format(running.writtenWords)} words written'
                                    : '${running.writtenWords} / ${running.targetWords} words (${(running.targetWords > 0 ? running.writtenWords * 100 ~/ running.targetWords : 0)}%)',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              if (running.projectType == ProjectType.fixed)
                                LinearProgressIndicator(
                                  value: running.targetWords > 0 ? min(1.0, running.writtenWords / running.targetWords) : 0,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Started ${DateFormat.yMMMd().format(running.startDate)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.push('/projects/${running.id}');
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 16),
                                    label: const Text('Open'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // If no running project, offer "+ Start Next Project Run"
                  if (running == null) ...[
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/projects/create?cloneFrom=${primary.id}');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Start Next Project Run'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SECTION 2: COMPLETED RUNS
                  if (completed.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.archive_outlined, color: theme.colorScheme.outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'COMPLETED RUNS (READ-ONLY)',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...completed.map((comp) {
                      final finishDate = comp.actualFinishDate ?? comp.updatedAt;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  comp.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${NumberFormat('#,###').format(comp.writtenWords)} words written',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Finished on ${DateFormat.yMMMd().format(finishDate)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            tooltip: 'Delete completed run',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Completed Run?'),
                                  content: Text('Are you sure you want to delete this completed record for "${comp.name}"? This will not affect other runs.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(projectsProvider.notifier).deleteProject(comp.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/projects/${comp.id}');
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = group.primaryProject;
    final isOngoing = project.projectType == ProjectType.ongoing;
    final progress = project.targetWords > 0 ? project.writtenWords / project.targetWords : 0.0;
    final percent = (progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          if (group.hasMultipleRuns) {
            _showGroupRunsSheet(context, ref);
          } else {
            context.go('/projects/${project.id}');
          }
        },
        onLongPress: () => _showCoverActionSheet(context, ref, project),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Book Cover (3:4 ratio)
              BookCoverWidget(
                title: project.name,
                coverImagePath: project.coverImagePath,
                coverType: project.coverType,
                width: 75,
                height: 100,
                borderRadius: 6.0,
                showTitle: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: project.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOngoing
                          ? '${NumberFormat('#,###').format(project.writtenWords)} words written'
                          : '${project.writtenWords} / ${project.targetWords} words ($percent%)',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (!isOngoing) ...[
                      LinearProgressIndicator(
                        value: min(1.0, progress),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${project.dailyWordTarget} words/day',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (project.projectStreak > 0)
                          Row(
                            children: [
                              Icon(Icons.local_fire_department, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 2),
                              Text(
                                '${project.projectStreak}d streak',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (group.hasCompletedRuns && group.runningProject != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '📚 ${group.completedProjects.length} Completed Run${group.completedProjects.length > 1 ? 's' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dedicated Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
                  child: Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ProjectStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ProjectStatus.active:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case ProjectStatus.paused:
        backgroundColor = theme.colorScheme.secondaryContainer;
        textColor = theme.colorScheme.onSecondaryContainer;
        break;
      case ProjectStatus.frozen:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        break;
      case ProjectStatus.completed:
        backgroundColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        break;
      case ProjectStatus.upcoming:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Card(
      elevation: 0,
      color: backgroundColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
        child: Text(
          status.name.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 9.0,
          ),
        ),
      ),
    );
  }
}
