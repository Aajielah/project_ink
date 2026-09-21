import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';
import 'chapter_dialog.dart';
import 'scene_dialog.dart';

class OutlineScreen extends ConsumerStatefulWidget {
  final String universeId;

  const OutlineScreen({required this.universeId, super.key});

  @override
  ConsumerState<OutlineScreen> createState() => _OutlineScreenState();
}

class _OutlineScreenState extends ConsumerState<OutlineScreen> {
  String _selectedActFilter = 'All';
  final Set<String> _expandedChapterIds = {};

  final List<String> _actFilters = [
    'All',
    'Prologue',
    'Act I',
    'Act IIA',
    'Act IIB',
    'Act III',
    'Epilogue',
  ];

  Color _getTensionColor(int level) {
    if (level <= 3) return AppColors.deepTeal;
    if (level <= 6) return AppColors.amberGold;
    if (level <= 8) return Colors.orange;
    return AppColors.crimsonInk;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return AppColors.emerald;
      case 'drafting':
        return AppColors.royalBlue;
      case 'revised':
        return AppColors.violetLore;
      case 'idea':
        return Colors.grey;
      case 'outlined':
      default:
        return AppColors.amberGold;
    }
  }

  void _showAddChapterDialog([String? act]) {
    showDialog(
      context: context,
      builder: (ctx) => ChapterDialog(
        universeId: widget.universeId,
        defaultAct: act == 'All' ? null : act,
      ),
    );
  }

  void _showEditChapterDialog(Chapter chapter) {
    showDialog(
      context: context,
      builder: (ctx) => ChapterDialog(
        universeId: widget.universeId,
        existingChapter: chapter,
      ),
    );
  }

  void _showAddSceneDialog(String chapterId) {
    showDialog(
      context: context,
      builder: (ctx) => SceneDialog(
        universeId: widget.universeId,
        chapterId: chapterId,
      ),
    );
  }

  void _showEditSceneDialog(String chapterId, Scene scene) {
    showDialog(
      context: context,
      builder: (ctx) => SceneDialog(
        universeId: widget.universeId,
        chapterId: chapterId,
        existingScene: scene,
      ),
    );
  }

  void _confirmDeleteChapter(Chapter chapter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter?'),
        content: Text(
          'Delete Chapter ${chapter.chapterNumber}: "${chapter.title}"? All scenes within this chapter will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(outlineRepositoryProvider).deleteChapter(chapter.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteScene(Scene scene) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scene?'),
        content: Text('Delete scene "${scene.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(outlineRepositoryProvider).deleteScene(scene.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTemplatePicker() {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Story Structure Templates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isDesktop)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a proven outline structure with chapters, acts, and core narrative beats.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.amberGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on, color: AppColors.amberGold),
            ),
            title: const Text('Save the Cat! (15 Narrative Beats)'),
            subtitle: const Text('Opening Image, Catalyst, Debate, Midpoint, All Hope is Lost, Finale...'),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(outlineRepositoryProvider).applyTemplate(widget.universeId, 'save_the_cat');
            },
          ),
          const Divider(),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories, color: AppColors.royalBlue),
            ),
            title: const Text('Classic Three-Act Structure (8 Milestones)'),
            subtitle: const Text('The Hook, Inciting Incident, Plot Points 1 & 2, Midpoint Reversal, Climax...'),
            onTap: () async {
              Navigator.of(context).pop();
              await ref.read(outlineRepositoryProvider).applyTemplate(widget.universeId, 'three_act');
            },
          ),
        ],
      ),
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(child: content),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(universeChaptersProvider(widget.universeId));
    final allScenesAsync = ref.watch(allUniverseScenesProvider(widget.universeId));

    return Scaffold(
      body: Column(
        children: [
          // Header / Stats Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              final badgesWidget = chaptersAsync.when(
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
                data: (chapters) {
                  final totalWords = chapters.fold<int>(
                    0,
                    (sum, c) => sum + c.estimatedWordCount,
                  );
                  final sceneCount = allScenesAsync.value?.length ?? 0;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildBadge('${chapters.length} Chapters', AppColors.amberGold),
                      _buildBadge('$sceneCount Scenes', AppColors.royalBlue),
                      _buildBadge('$totalWords Est. Words', AppColors.deepTeal),
                    ],
                  );
                },
              );

              final actionButtons = Row(
                mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (isNarrow)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 15),
                        label: const Text('Templates'),
                        onPressed: _showTemplatePicker,
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Templates'),
                      onPressed: _showTemplatePicker,
                    ),
                  const SizedBox(width: 8),
                  if (isNarrow)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Chapter'),
                        onPressed: () => _showAddChapterDialog(_selectedActFilter),
                      ),
                    )
                  else
                    FilledButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Chapter'),
                      onPressed: () => _showAddChapterDialog(_selectedActFilter),
                    ),
                ],
              );

              if (isNarrow) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badgesWidget,
                      const SizedBox(height: 10),
                      actionButtons,
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    badgesWidget,
                    const Spacer(),
                    actionButtons,
                  ],
                ),
              );
            },
          ),

          // Act Filter Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _actFilters.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final act = _actFilters[index];
                final isSelected = _selectedActFilter == act;
                return ChoiceChip(
                  label: Text(act),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedActFilter = act);
                  },
                );
              },
            ),
          ),

          // Chapter & Scene Content List
          Expanded(
            child: chaptersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading chapters: $err')),
              data: (chapters) {
                final filtered = _selectedActFilter == 'All'
                    ? chapters
                    : chapters.where((c) => c.act == _selectedActFilter).toList();

                if (chapters.isEmpty) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.amberGold.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 36,
                                color: AppColors.amberGold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No Chapters Outlined Yet',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by outlining your opening chapter or use a classic beat template to automatically generate story structure.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Apply Template'),
                                  onPressed: _showTemplatePicker,
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Chapter'),
                                  onPressed: () => _showAddChapterDialog(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No chapters in "$_selectedActFilter" yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final chapter = filtered[index];
                    final isExpanded = _expandedChapterIds.contains(chapter.id);

                    return _buildChapterCard(context, chapter, isExpanded);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, Chapter chapter, bool isExpanded) {
    final statusColor = _getStatusColor(chapter.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chapter Number Circle
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.amberGold.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${chapter.chapterNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.amberGold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.deepTeal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              chapter.act.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepTeal,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              chapter.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Text(
                            '~${chapter.estimatedWordCount} words',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      if (chapter.objective != null && chapter.objective!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                chapter.objective!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions & Toggle
                IconButton(
                  tooltip: isExpanded ? 'Collapse Scenes' : 'Expand Scenes',
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedChapterIds.remove(chapter.id);
                      } else {
                        _expandedChapterIds.add(chapter.id);
                      }
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditChapterDialog(chapter);
                    } else if (val == 'add_scene') {
                      _showAddSceneDialog(chapter.id);
                    } else if (val == 'delete') {
                      _confirmDeleteChapter(chapter);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'add_scene',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('Add Scene Beat'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Chapter'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded Scenes Sublist
          if (isExpanded) _buildScenesSection(context, chapter.id),
        ],
      ),
    );
  }

  Widget _buildScenesSection(BuildContext context, String chapterId) {
    final scenesAsync = ref.watch(chapterScenesProvider(chapterId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SCENE BEATS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Scene'),
                onPressed: () => _showAddSceneDialog(chapterId),
              ),
            ],
          ),
          const SizedBox(height: 6),
          scenesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error loading scenes: $e'),
            data: (scenes) {
              if (scenes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'No scenes added to this chapter yet. Tap "Add Scene" to draft beats.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: scenes.map((scene) {
                  final tensionColor = _getTensionColor(scene.tensionLevel);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scene indicator & tension
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tensionColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on, size: 12, color: tensionColor),
                              const SizedBox(width: 2),
                              Text(
                                '${scene.tensionLevel}/10',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tensionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${scene.sceneNumber}. ${scene.title}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (scene.locationName != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 11, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Text(
                                      scene.locationName!,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                              if (scene.summary != null && scene.summary!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  scene.summary!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showEditSceneDialog(chapterId, scene),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _confirmDeleteScene(scene),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
