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
  bool _isSidebarVisible = true; // Zen mode toggle on desktop
  int _chapterBeatIndex = 0; // 0: Start, 1: Middle, 2: End/Cliffhanger, 3: Full Chapter View

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

  int _getWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
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
      _chapterBeatIndex = 0;
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
        content: Text('Delete "${chapter.title}" and its chapter outline?'),
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
    setState(() {});
  }

  void _onArcContentChanged(String arcId, String val) {
    ref.read(arcRepositoryProvider).updateArcContent(arcId, val);
    setState(() {});
  }

  void _onChapterStartChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, startBeat: val);
    setState(() {});
  }

  void _onChapterMiddleChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, middleBeat: val);
    setState(() {});
  }

  void _onChapterEndChanged(String chapterId, String val) {
    ref.read(chapterRepositoryProvider).updateChapterBeats(id: chapterId, endBeat: val);
    setState(() {});
  }

  void _onCustomContentChanged(String sectionId, String val) {
    ref.read(customSectionRepositoryProvider).updateCustomSectionContent(sectionId, val);
    setState(() {});
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

        // Main Pure Writer Pane
        final mainEditorWidget = _buildPureWriterPane(
          project: project,
          arcs: arcs,
          chapters: chapters,
          customSections: customSections,
          showSidebarToggle: isWide,
        );

        if (isWide) {
          // Desktop Split / Zen Layout
          return Scaffold(
            body: Row(
              children: [
                if (_isSidebarVisible) ...[
                  SizedBox(
                    width: 290,
                    child: sidebarWidget,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                ],
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

  // --- Left Sidebar ---

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
                  leading: const Icon(Icons.lightbulb_outline, size: 20),
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
                        _chapterBeatIndex = 0;
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

  // --- Main Pure Writer Pane (Full Space, No Confining Boxes) ---

  Widget _buildPureWriterPane({
    required Project project,
    required List<Arc> arcs,
    required List<Chapter> chapters,
    required List<CustomSection> customSections,
    required bool showSidebarToggle,
  }) {
    switch (_activeSection) {
      case ActiveWorkspaceSection.generalIdea:
        return _buildPureGeneralIdea(showSidebarToggle);

      case ActiveWorkspaceSection.arc:
        final arc = arcs.firstWhere(
          (a) => a.id == _selectedItemId,
          orElse: () => arcs.isNotEmpty
              ? arcs.first
              : Arc(
                  id: '',
                  projectId: widget.projectId,
                  title: 'Arc 1',
                  content: '',
                  orderIndex: 0,
                  createdAt: DateTime.now(),
                ),
        );
        return _buildPureArc(arc, showSidebarToggle);

      case ActiveWorkspaceSection.chapter:
        final chapter = chapters.firstWhere(
          (c) => c.id == _selectedItemId,
          orElse: () => chapters.isNotEmpty
              ? chapters.first
              : Chapter(
                  id: '',
                  projectId: widget.projectId,
                  title: 'Chapter 1',
                  orderIndex: 0,
                  startBeat: '',
                  middleBeat: '',
                  endBeat: '',
                  createdAt: DateTime.now(),
                ),
        );
        return _buildPureChapter(chapter, showSidebarToggle);

      case ActiveWorkspaceSection.customSection:
        final section = customSections.firstWhere(
          (s) => s.id == _selectedItemId,
          orElse: () => customSections.isNotEmpty
              ? customSections.first
              : CustomSection(
                  id: '',
                  projectId: widget.projectId,
                  title: 'Section',
                  content: '',
                  orderIndex: 0,
                  createdAt: DateTime.now(),
                ),
        );
        return _buildPureCustomSection(section, showSidebarToggle);
    }
  }

  // 1. Pure General Idea (Full Screen Canvas)
  Widget _buildPureGeneralIdea(bool showSidebarToggle) {
    return Column(
      children: [
        _buildPureTopBar(
          title: 'General Idea',
          tag: 'Brainstorm Canvas',
          tagColor: AppColors.amberGold,
          onRename: null,
          showSidebarToggle: showSidebarToggle,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: TextField(
              controller: _generalIdeaController,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 17,
                height: 1.8,
                letterSpacing: 0.2,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Start writing your general idea piece by piece...\n\nPremise, world rules, character thoughts, and raw brainstorming. The whole space is yours to write without boundaries.',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onGeneralIdeaChanged,
            ),
          ),
        ),
        _buildPureBottomStatusBar(text: _generalIdeaController.text),
      ],
    );
  }

  // 2. Pure Arc (Full Screen Canvas)
  Widget _buildPureArc(Arc arc, bool showSidebarToggle) {
    if (_loadedArcId != arc.id) {
      _loadedArcId = arc.id;
      _arcContentController.text = arc.content;
    }

    return Column(
      children: [
        _buildPureTopBar(
          title: arc.title,
          tag: 'Arc Narrative',
          tagColor: AppColors.amberGold,
          onRename: () => _renameArc(arc),
          showSidebarToggle: showSidebarToggle,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: TextField(
              controller: _arcContentController,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 17,
                height: 1.8,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                hintText:
                    'Write everything for ${arc.title} here...\n\nOutline the overarching progression, milestones, key conflicts, and character development across this arc.',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _onArcContentChanged(arc.id, val),
            ),
          ),
        ),
        _buildPureBottomStatusBar(text: _arcContentController.text),
      ],
    );
  }

  // 3. Pure Chapter (Full Screen Pure Writer Canvas with 3-Beat Navigation)
  Widget _buildPureChapter(Chapter chapter, bool showSidebarToggle) {
    if (_loadedChapterId != chapter.id) {
      _loadedChapterId = chapter.id;
      _chapterStartController.text = chapter.startBeat;
      _chapterMiddleController.text = chapter.middleBeat;
      _chapterEndController.text = chapter.endBeat;
    }

    // Determine current active text for bottom status bar
    String activeText = '';
    if (_chapterBeatIndex == 0) {
      activeText = _chapterStartController.text;
    } else if (_chapterBeatIndex == 1) {
      activeText = _chapterMiddleController.text;
    } else if (_chapterBeatIndex == 2) {
      activeText = _chapterEndController.text;
    } else {
      activeText = '${_chapterStartController.text}\n\n${_chapterMiddleController.text}\n\n${_chapterEndController.text}';
    }

    return Column(
      children: [
        // Top Header
        _buildPureTopBar(
          title: chapter.title,
          tag: 'Chapter',
          tagColor: AppColors.royalBlue,
          onRename: () => _renameChapter(chapter),
          showSidebarToggle: showSidebarToggle,
        ),

        // Beat Selector Bar (Start, Middle, End, Combined)
        _buildChapterBeatSelector(chapter),

        // Pure Writer Full-Screen Writing Canvas
        Expanded(
          child: _chapterBeatIndex == 3
              ? _buildFullChapterContinuousView(chapter)
              : _buildSingleBeatFullCanvas(chapter),
        ),

        // Bottom Status Bar
        _buildPureBottomStatusBar(
          text: activeText,
          onAddNextChapter: _addChapter,
        ),
      ],
    );
  }

  Widget _buildSingleBeatFullCanvas(Chapter chapter) {
    TextEditingController controller;
    String hintText;
    ValueChanged<String> onChanged;

    if (_chapterBeatIndex == 0) {
      controller = _chapterStartController;
      hintText =
          'Start (Hook + Situation Setup):\n\nHow does this chapter open? Write the hook, immediate situation, mood, and opening scene... The entire screen is yours to write.';
      onChanged = (val) => _onChapterStartChanged(chapter.id, val);
    } else if (_chapterBeatIndex == 1) {
      controller = _chapterMiddleController;
      hintText =
          'Middle (Main Conflict + Development):\n\nWhat is the core friction or obstacle? Write the confrontation, escalation, dialogue, and turning developments...';
      onChanged = (val) => _onChapterMiddleChanged(chapter.id, val);
    } else {
      controller = _chapterEndController;
      hintText =
          'End / Cliffhanger (Turning Point or Hook):\n\nHow does this chapter conclude? Write the twist, revelation, dramatic exit, or cliffhanger leading to the next chapter...';
      onChanged = (val) => _onChapterEndChanged(chapter.id, val);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          fontSize: 17,
          height: 1.8,
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Combined Continuous View (Flowing Document)
  Widget _buildFullChapterContinuousView(Chapter chapter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContinuousBeatHeader('1. START (Hook & Situation Setup)', AppColors.emerald),
          const SizedBox(height: 10),
          TextField(
            controller: _chapterStartController,
            maxLines: null,
            minLines: 8,
            style: const TextStyle(fontSize: 17, height: 1.8),
            decoration: const InputDecoration(
              hintText: 'Write the opening hook and situation setup...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => _onChapterStartChanged(chapter.id, val),
          ),
          const Divider(height: 36),
          _buildContinuousBeatHeader('2. MIDDLE (Main Conflict & Development)', AppColors.amberGold),
          const SizedBox(height: 10),
          TextField(
            controller: _chapterMiddleController,
            maxLines: null,
            minLines: 12,
            style: const TextStyle(fontSize: 17, height: 1.8),
            decoration: const InputDecoration(
              hintText: 'Write the main conflict, escalation, and developments...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => _onChapterMiddleChanged(chapter.id, val),
          ),
          const Divider(height: 36),
          _buildContinuousBeatHeader('3. END / CLIFFHANGER (Turning Point)', AppColors.crimsonInk),
          const SizedBox(height: 10),
          TextField(
            controller: _chapterEndController,
            maxLines: null,
            minLines: 8,
            style: const TextStyle(fontSize: 17, height: 1.8),
            decoration: const InputDecoration(
              hintText: 'Write the ending twist, turning point, or cliffhanger...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => _onChapterEndChanged(chapter.id, val),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContinuousBeatHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildChapterBeatSelector(Chapter chapter) {
    final beats = [
      {'title': 'Start', 'sub': 'Hook & Setup', 'color': AppColors.emerald, 'icon': Icons.play_arrow_rounded},
      {'title': 'Middle', 'sub': 'Conflict', 'color': AppColors.amberGold, 'icon': Icons.flash_on_rounded},
      {'title': 'End / Cliffhanger', 'sub': 'Turning Point', 'color': AppColors.crimsonInk, 'icon': Icons.flag_rounded},
      {'title': 'Full Chapter', 'sub': 'All 3 Beats', 'color': AppColors.royalBlue, 'icon': Icons.menu_book_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5) ?? Theme.of(context).cardColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(beats.length, (index) {
            final b = beats[index];
            final isSelected = _chapterBeatIndex == index;
            final color = b['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSelected,
                avatar: Icon(
                  b['icon'] as IconData,
                  size: 15,
                  color: isSelected ? Colors.white : color,
                ),
                label: Text(
                  '${b['title']} (${b['sub']})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                selectedColor: color,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _chapterBeatIndex = index;
                    });
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  // 4. Pure Custom Section (Full Screen Canvas)
  Widget _buildPureCustomSection(CustomSection section, bool showSidebarToggle) {
    if (_loadedCustomId != section.id) {
      _loadedCustomId = section.id;
      _customContentController.text = section.content;
    }

    return Column(
      children: [
        _buildPureTopBar(
          title: section.title,
          tag: 'Custom Section',
          tagColor: AppColors.deepTeal,
          onRename: () => _renameCustomSection(section),
          showSidebarToggle: showSidebarToggle,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: TextField(
              controller: _customContentController,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 17,
                height: 1.8,
                letterSpacing: 0.2,
              ),
              decoration: InputDecoration(
                hintText:
                    'Write content for "${section.title}" here...\n\nCharacter profiles, magic systems, world lore, notes, or research. Full-screen writing space without boundaries.',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => _onCustomContentChanged(section.id, val),
            ),
          ),
        ),
        _buildPureBottomStatusBar(text: _customContentController.text),
      ],
    );
  }

  // Pure Writer Minimalist Top Bar
  Widget _buildPureTopBar({
    required String title,
    required String tag,
    required Color tagColor,
    VoidCallback? onRename,
    required bool showSidebarToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.4) ?? Theme.of(context).cardColor.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showSidebarToggle) ...[
            IconButton(
              icon: Icon(
                _isSidebarVisible ? Icons.fullscreen : Icons.view_sidebar_outlined,
                size: 20,
              ),
              tooltip: _isSidebarVisible ? 'Zen Mode (Hide Sidebar)' : 'Show Sidebar',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _isSidebarVisible = !_isSidebarVisible;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: tagColor,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: onRename,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRename != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pure Writer Minimalist Bottom Status Bar
  Widget _buildPureBottomStatusBar({
    required String text,
    VoidCallback? onAddNextChapter,
  }) {
    final words = _getWordCount(text);
    final chars = text.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5) ?? Theme.of(context).cardColor.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: AppColors.emerald.withOpacity(0.85)),
          const SizedBox(width: 6),
          Text(
            'Auto-saved',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 18),
          Text(
            '$words words  •  $chars characters',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          if (onAddNextChapter != null)
            TextButton.icon(
              onPressed: onAddNextChapter,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Next Chapter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      ),
    );
  }
}
