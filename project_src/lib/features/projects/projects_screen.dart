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
            final active = projects.where((p) => p.status == ProjectStatus.active).toList();
            final inactive = projects.where((p) => p.status == ProjectStatus.paused || p.status == ProjectStatus.frozen || p.status == ProjectStatus.upcoming).toList();
            final completed = projects.where((p) => p.status == ProjectStatus.completed).toList();

            return TabBarView(
              children: [
                _ProjectList(projects: active, emptyMessage: 'No active projects. Start a new writing project today!'),
                _ProjectList(projects: inactive, emptyMessage: 'No paused or frozen projects.'),
                _ProjectList(projects: completed, emptyMessage: 'No completed projects yet. Keep writing!'),
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

class _ProjectList extends ConsumerWidget {
  final List<ProjectModel> projects;
  final String emptyMessage;

  const _ProjectList({super.key, required this.projects, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (projects.isEmpty) {
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
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _ProjectCard(
          key: ValueKey(project.id),
          index: index,
          project: project,
        );
      },
      onReorder: (oldIndex, newIndex) async {
        final tabList = List<ProjectModel>.from(projects);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = tabList.removeAt(oldIndex);
        tabList.insert(newIndex, item);

        final allProjects = ref.read(projectsProvider).value ?? [];
        final otherProjects = allProjects.where((p) => !projects.any((tp) => tp.id == p.id)).toList();
        final newAllProjects = [...tabList, ...otherProjects];

        await ref.read(projectsProvider.notifier).reorderProjects(newAllProjects);
      },
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final int index;
  final ProjectModel project;

  const _ProjectCard({super.key, required this.index, required this.project});

  Future<void> _pickCustomCover(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final pickedPath = pickedFile.path;
        final appDir = await getApplicationDocumentsDirectory();
        
        // Check if an identical image already exists to avoid duplication
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

  Future<void> _rollRandomCover(BuildContext context, WidgetRef ref) async {
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

  Future<void> _removeCover(BuildContext context, WidgetRef ref) async {
    final updated = project.copyWith(
      coverType: null,
      coverImagePath: null,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(projectsProvider.notifier).updateProject(updated);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover cover removed.')),
      );
    }
  }

  void _showCoverActionSheet(BuildContext context, WidgetRef ref) {
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
                  _pickCustomCover(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.casino),
                title: const Text('🖼 Choose Random Default Cover'),
                onTap: () {
                  Navigator.pop(context);
                  _rollRandomCover(context, ref);
                },
              ),
              if (project.coverType != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('❌ Remove Cover', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeCover(context, ref);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOngoing = project.projectType == ProjectType.ongoing;
    final progress = project.targetWords > 0 ? project.writtenWords / project.targetWords : 0.0;
    final percent = (progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => context.go('/projects/${project.id}'),
        onLongPress: () => _showCoverActionSheet(context, ref),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dedicated Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
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
