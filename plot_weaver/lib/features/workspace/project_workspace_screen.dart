import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../projects/rename_dialog.dart';

enum ActiveWorkspaceSection {
  generalIdea,
  arc,
  chapter,
  customSection,
}

class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectWorkspaceScreen({required this.projectId, super.key});

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends ConsumerState<ProjectWorkspaceScreen> {
  ActiveWorkspaceSection _activeSection = ActiveWorkspaceSection.generalIdea;
  String? _selectedItemId; // ID of the active Arc, Chapter, or CustomSection

  // Text editing controllers
  final TextEditingController _generalIdeaController = TextEditingController();
  final TextEditingController _arcContentController = TextEditingController();
  final TextEditingController _chapterStartController = TextEditingController();
  final TextEditingController _chapterMiddleController = TextEditingController();
  final TextEditingController _chapterEndController = TextEditingController();
  final TextEditingController _customContentController = TextEditingController();

  String? _loadedGeneralIdea;
  String? _loadedArcId;
  String? _loadedChapterId;
  String? _loadedCustomId;

  @override
  void dispose() {
    _generalIdeaController.dispose();
    _arcContentController.dispose();
    _chapterStartController.dispose();
    _chapterMiddleController.dispose();
    _chapterEndController.dispose();
    _customContentController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _renameProject(Project project) async {
    final newTitle = await RenameDialog.show(
      context,
      currentTitle: project.name,
      headingType: 'Project',
    );
    if (newTitle != null && newTitle != project.name) {
      await ref.read(projectRepositoryProvider).updateProjectInfo(
            id: project.id,
            name: newTitle,
            genre: project.genre,
            bookId: project.bookId,
          );
    }
  }

  Future<void> _addArc() async {
    final arc = await ref.read(arcRepositoryProvider).createArc(widget.projectId);
    setState(() {
      _activeSection = ActiveWorkspaceSection.arc;
      _selectedItemId = arc.id;
    });
  }

  Future<void> _renameArc(Arc arc) async {
    final newTitle = await RenameDialog.show(
      context,
      currentTitle: arc.title,
      headingType: 'Arc',
    );
    if (newTitle != null && newTitle != arc.title) {
      await ref.read(arcRepositoryProvider).updateArcTitle(arc.id, newTitle);
    }
  }

  Future<void> _deleteArc(Arc arc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Arc?'),
        content: Text('Delete "${arc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(arcRepositoryProvider).deleteArc(arc.id);
      if (_selectedItemId == arc.id) {
        setState(() {
          _activeSection = ActiveWorkspaceSection.generalIdea;
          _selectedItemId = null;
        });
      }
    }
  }

  Future<void> _addChapter() async {
    final chapter = await ref.read(chapterRepositoryProvider).createChapter(widget.projectId);
    setState(() {
      _activeSection = ActiveWorkspaceSection.chapter;
      _selectedItemId = chapter.id;
    });
  }

  Future<void> _renameChapter(Chapter chapter) async {
    final newTitle = await RenameDialog.show(
      context,
      currentTitle: chapter.title,
      headingType: 'Chapter',
    );
    if (newTitle != null && newTitle != chapter.title) {
      await ref.read(chapterRepositoryProvider).updateChapterTitle(chapter.id, newTitle);
    }
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter?'),
        content: Text('Delete "${chapter.title}" and its 3-beat outline?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(chapterRepositoryProvider).deleteChapter(chapter.id);
      if (_selectedItemId == chapter.id) {
        setState(() {
          _activeSection = ActiveWorkspaceSection.generalIdea;
          _selectedItemId = null;
        });
      }
    }
  }

  Future<void> _addCustomSection() async {
    final title = await RenameDialog.show(
      context,
      currentTitle: 'Characters & Cast',
      headingType: 'Custom Section',
    );
    if (title != null && title.isNotEmpty) {
      final section = await ref.read(customSectionRepositoryProvider).createCustomSection(
            widget.projectId,
            title,
          );
      setState(() {
        _activeSection = ActiveWorkspaceSection.customSection;
        _selectedItemId = section.id;
      });
    }
  }

  Future<void> _renameCustomSection(CustomSection section) async {
    final newTitle = await RenameDialog.show(
      context,
      currentTitle: section.title,
      headingType: 'Custom Section',
    );
    if (newTitle != null && newTitle != section.title) {
      await ref.read(customSectionRepositoryProvider).updateCustomSectionTitle(section.id, newTitle);
    }
  }

  Future<void> _deleteCustomSection(CustomSection section) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Section?'),
        content: Text('Delete "${section.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customSectionRepositoryProvider).deleteCustomSection(section.id);
      if (_selectedItemId == section.id) {
        setState(() {
          _activeSection = ActiveWorkspaceSection.generalIdea;
          _selectedItemId = null;
        });
      }
    }
  }

  // --- Auto-Save Handlers ---

  void _onGeneralIdeaChanged(String val) {
    ref.read(projectRepositoryProvider).updateGeneralIdea(widget.projectId, val);
  }

  void _onArcContentChanged(String arcId, String val) {
    ref.read(arcRepositoryProvider).updateArcContent(arcId, val);
  }

  void _onChapterStartChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, startBeat: val);
  }

  void _onChapterMiddleChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, middleBeat: val);
  }

  void _onChapterEndChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, endBeat: val);
  }

  void _onCustomContentChanged(String sectionId, String val) {
    ref.read(customSectionRepositoryProvider).updateCustomSectionContent(sectionId, val);
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));
    final arcsAsync = ref.watch(projectArcsProvider(widget.projectId));
    final chaptersAsync = ref.watch(projectChaptersProvider(widget.projectId));
    final customSectionsAsync = ref.watch(projectCustomSectionsProvider(widget.projectId));

    final isWide = MediaQuery.of(context).size.width >= 800;

    return projectAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading project: $e'))),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Project not found')),
          );
        }

        // Sync general idea controller
        if (_loadedGeneralIdea != project.generalIdea && !_generalIdeaController.text.contains(project.generalIdea)) {
          _loadedGeneralIdea = project.generalIdea;
          _generalIdeaController.text = project.generalIdea;
        }

        final arcs = arcsAsync.value ?? [];
        final chapters = chaptersAsync.value ?? [];
        final customSections = customSectionsAsync.value ?? [];

        // Sidebar Widget
        final sidebarWidget = _buildSidebar(
          project: project,
          arcs: arcs,
          chapters: chapters,
          customSections: customSections,
          isDrawer: !isWide,
        );

        // Main Editor Pane Widget
        final mainEditorWidget = _buildMainPane(
          project: project,
          arcs: arcs,
          chapters: chapters,
          customSections: customSections,
        );

        if (isWide) {
          // Desktop Split Layout
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: sidebarWidget,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: mainEditorWidget,
                ),
              ],
            ),
          );
        } else {
          // Mobile Drawer Layout
          return Scaffold(
            appBar: AppBar(
              title: Text(
                project.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Home',
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(child: sidebarWidget),
            ),
            body: mainEditorWidget,
          );
        }
      },
    );
  }

  // --- Left Sidebar (Option B) ---

  Widget _buildSidebar({
    required Project project,
    required List<Arc> arcs,
    required List<Chapter> chapters,
    required List<CustomSection> customSections,
    required bool isDrawer,
  }) {
    return Container(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Title Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  tooltip: 'Back to Home',
                  onPressed: () => context.go('/'),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _renameProject(project),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                project.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.amberGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.genre.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amberGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable navigation list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. General Idea
                ListTile(
                  leading: const Icon(Icons.description_outlined, size: 20),
                  title: const Text('General Idea', style: TextStyle(fontWeight: FontWeight.w600)),
                  selected: _activeSection == ActiveWorkspaceSection.generalIdea,
                  selectedTileColor: AppColors.amberGold.withOpacity(0.12),
                  selectedColor: AppColors.amberGold,
                  onTap: () {
                    setState(() {
                      _activeSection = ActiveWorkspaceSection.generalIdea;
                      _selectedItemId = null;
                    });
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),

                const Divider(height: 16),

                // 2. Arcs Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, size: 16, color: AppColors.amberGold),
                      const SizedBox(width: 6),
                      const Text(
                        'ARCS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add Arc',
                        visualDensity: VisualDensity.compact,
                        onPressed: _addArc,
                      ),
                    ],
                  ),
                ),

                // Arcs List
                ...arcs.map((arc) {
                  final isSelected =
                      _activeSection == ActiveWorkspaceSection.arc && _selectedItemId == arc.id;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 24, right: 8),
                    title: Text(
                      arc.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.amberGold.withOpacity(0.12),
                    selectedColor: AppColors.amberGold,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          tooltip: 'Rename',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _renameArc(arc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 15, color: Colors.grey),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _deleteArc(arc),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _activeSection = ActiveWorkspaceSection.arc;
                        _selectedItemId = arc.id;
                      });
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  );
                }),

                const Divider(height: 16),

                // 3. Chapter Outline Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_outlined, size: 16, color: AppColors.royalBlue),
                      const SizedBox(width: 6),
                      const Text(
                        'CHAPTER OUTLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add Chapter',
                        visualDensity: VisualDensity.compact,
                        onPressed: _addChapter,
                      ),
                    ],
                  ),
                ),

                // Chapters List
                ...chapters.map((ch) {
                  final isSelected =
                      _activeSection == ActiveWorkspaceSection.chapter && _selectedItemId == ch.id;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 24, right: 8),
                    title: Text(
                      ch.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.royalBlue.withOpacity(0.12),
                    selectedColor: AppColors.royalBlue,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          tooltip: 'Rename',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _renameChapter(ch),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 15, color: Colors.grey),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _deleteChapter(ch),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _activeSection = ActiveWorkspaceSection.chapter;
                        _selectedItemId = ch.id;
                      });
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  );
                }),

                const Divider(height: 16),

                // 4. Custom Sections Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.extension_outlined, size: 16, color: AppColors.deepTeal),
                      const SizedBox(width: 6),
                      const Text(
                        'CUSTOM SECTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        tooltip: 'Add Custom Section',
                        visualDensity: VisualDensity.compact,
                        onPressed: _addCustomSection,
                      ),
                    ],
                  ),
                ),

                // Custom Sections List
                ...customSections.map((sec) {
                  final isSelected =
                      _activeSection == ActiveWorkspaceSection.customSection && _selectedItemId == sec.id;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 24, right: 8),
                    title: Text(
                      sec.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    selectedTileColor: AppColors.deepTeal.withOpacity(0.12),
                    selectedColor: AppColors.deepTeal,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          tooltip: 'Rename',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _renameCustomSection(sec),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 15, color: Colors.grey),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _deleteCustomSection(sec),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _activeSection = ActiveWorkspaceSection.customSection;
                        _selectedItemId = sec.id;
                      });
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),

          // Bottom Action: Add Custom Heading
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Custom Section'),
                onPressed: _addCustomSection,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Editor Workspace ---

  Widget _buildMainPane({
    required Project project,
    required List<Arc> arcs,
    required List<Chapter> chapters,
    required List<CustomSection> customSections,
  }) {
    switch (_activeSection) {
      case ActiveWorkspaceSection.generalIdea:
        return _buildGeneralIdeaEditor(project);

      case ActiveWorkspaceSection.arc:
        final arc = arcs.firstWhere(
          (a) => a.id == _selectedItemId,
          orElse: () => arcs.isNotEmpty ? arcs.first : Arc(
            id: '',
            projectId: widget.projectId,
            title: 'Arc',
            content: '',
            orderIndex: 0,
            createdAt: DateTime.now(),
          ),
        );
        return _buildArcEditor(arc);

      case ActiveWorkspaceSection.chapter:
        final chapter = chapters.firstWhere(
          (c) => c.id == _selectedItemId,
          orElse: () => chapters.isNotEmpty ? chapters.first : Chapter(
            id: '',
            projectId: widget.projectId,
            title: 'Chapter',
            orderIndex: 0,
            startBeat: '',
            middleBeat: '',
            endBeat: '',
            createdAt: DateTime.now(),
          ),
        );
        return _buildChapterEditor(chapter);

      case ActiveWorkspaceSection.customSection:
        final section = customSections.firstWhere(
          (s) => s.id == _selectedItemId,
          orElse: () => customSections.isNotEmpty ? customSections.first : CustomSection(
            id: '',
            projectId: widget.projectId,
            title: 'Section',
            content: '',
            orderIndex: 0,
            createdAt: DateTime.now(),
          ),
        );
        return _buildCustomSectionEditor(section);
    }
  }

  // 1. General Idea Editor
  Widget _buildGeneralIdeaEditor(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: AppColors.amberGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'General Idea',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'This is where you add all you want piece by piece. A wide text area for premises, world thoughts, or anything you brainstorm.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _generalIdeaController,
                    maxLines: null,
                    minLines: 16,
                    decoration: const InputDecoration(
                      hintText: 'Start writing your general idea here piece by piece...\n\n• Story core premise\n• Primary motivation & stakes\n• Themes, tone, or key scenes\n• Raw brainstorming thoughts...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.6),
                    onChanged: _onGeneralIdeaChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Arc Editor
  Widget _buildArcEditor(Arc arc) {
    if (_loadedArcId != arc.id) {
      _loadedArcId = arc.id;
      _arcContentController.text = arc.content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timeline, color: AppColors.amberGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _renameArc(arc),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              arc.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.amberGold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Define the narrative movement, major turning points, and progression of this arc.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _arcContentController,
                    maxLines: null,
                    minLines: 14,
                    decoration: InputDecoration(
                      hintText: 'Outline what happens in ${arc.title}...\n\n• What is the starting state of the characters?\n• What inciting incident propels this arc forward?\n• What climax concludes this arc?',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.6),
                    onChanged: (val) => _onArcContentChanged(arc.id, val),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Chapter Outline Editor (3-Beat Template)
  Widget _buildChapterEditor(Chapter chapter) {
    if (_loadedChapterId != chapter.id) {
      _loadedChapterId = chapter.id;
      _chapterStartController.text = chapter.startBeat;
      _chapterMiddleController.text = chapter.middleBeat;
      _chapterEndController.text = chapter.endBeat;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Title & Universal Rename
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories, color: AppColors.royalBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _renameChapter(chapter),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              chapter.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.royalBlue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '3-Beat Chapter Outline: Hook the reader at the start, escalate conflict in the middle, and exit on a sharp cliffhanger.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),

              // Beat 1: Start (Hook + Situation Setup)
              _buildBeatCard(
                title: 'Start',
                subtitle: 'Hook + Situation Setup',
                accentColor: AppColors.emerald,
                icon: Icons.play_arrow_rounded,
                controller: _chapterStartController,
                hintText: 'How does this chapter open? What is the immediate hook, opening situation, emotional tone, and setup?',
                onChanged: (val) => _onChapterStartChanged(chapter.id, val),
              ),

              const SizedBox(height: 18),

              // Beat 2: Middle (Main Conflict + Development)
              _buildBeatCard(
                title: 'Middle',
                subtitle: 'Main Conflict + Development',
                accentColor: AppColors.amberGold,
                icon: Icons.flash_on_rounded,
                controller: _chapterMiddleController,
                hintText: 'What is the main friction or challenge in this chapter? How do the stakes escalate? What action or discovery happens?',
                onChanged: (val) => _onChapterMiddleChanged(chapter.id, val),
              ),

              const SizedBox(height: 18),

              // Beat 3: End / Cliffhanger (Turning Point or Hook)
              _buildBeatCard(
                title: 'End / Cliffhanger',
                subtitle: 'Turning Point or Hook',
                accentColor: AppColors.crimsonInk,
                icon: Icons.flag_rounded,
                controller: _chapterEndController,
                hintText: 'How does the chapter end? What unexpected turn, revelation, decision, or cliffhanger pulls the reader into the next chapter?',
                onChanged: (val) => _onChapterEndChanged(chapter.id, val),
              ),

              const SizedBox(height: 24),

              // Add Next Chapter Button
              Center(
                child: FilledButton.icon(
                  onPressed: _addChapter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Next Chapter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeatCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($subtitle)',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Content text field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: 4,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14.5, height: 1.5),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Custom Section Editor
  Widget _buildCustomSectionEditor(CustomSection section) {
    if (_loadedCustomId != section.id) {
      _loadedCustomId = section.id;
      _customContentController.text = section.content;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.extension_outlined, color: AppColors.deepTeal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _renameCustomSection(section),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              section.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.deepTeal),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Custom section created by you. Tap the title anytime to rename.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _customContentController,
                    maxLines: null,
                    minLines: 14,
                    decoration: InputDecoration(
                      hintText: 'Add notes, worldbuilding, characters, or rules for "${section.title}"...',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15, height: 1.6),
                    onChanged: (val) => _onCustomContentChanged(section.id, val),
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
