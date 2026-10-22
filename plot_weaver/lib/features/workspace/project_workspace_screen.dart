import 'dart:async';
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

  // Text editing controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _generalIdeaController = TextEditingController();
  final TextEditingController _arcContentController = TextEditingController();
  final TextEditingController _chapterStartController = TextEditingController();
  final TextEditingController _chapterMiddleController = TextEditingController();
  final TextEditingController _chapterEndController = TextEditingController();
  final TextEditingController _customContentController = TextEditingController();

  String? _currentLoadedItemId;
  Timer? _titleDebounceTimer;

  @override
  void dispose() {
    _titleDebounceTimer?.cancel();
    _titleController.dispose();
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

  // --- Inline Title Auto-Save ---

  void _onTitleChanged(String itemId, String val) {
    _titleDebounceTimer?.cancel();
    _titleDebounceTimer = Timer(const Duration(milliseconds: 350), () {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return;
      switch (_activeSection) {
        case ActiveWorkspaceSection.arc:
          ref.read(arcRepositoryProvider).updateArcTitle(itemId, trimmed);
          break;
        case ActiveWorkspaceSection.chapter:
          ref.read(chapterRepositoryProvider).updateChapterTitle(itemId, trimmed);
          break;
        case ActiveWorkspaceSection.customSection:
          ref.read(customSectionRepositoryProvider).updateCustomSectionTitle(itemId, trimmed);
          break;
        case ActiveWorkspaceSection.generalIdea:
          break;
      }
    });
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
      _currentLoadedItemId = arc.id;
      _titleController.text = arc.title;
      _arcContentController.text = arc.content;
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
      if (_selectedItemId == arc.id) {
        _titleController.text = newTitle;
      }
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
          _currentLoadedItemId = null;
        });
      }
    }
  }

  Future<void> _addChapter() async {
    final chapter = await ref.read(chapterRepositoryProvider).createChapter(widget.projectId);
    setState(() {
      _activeSection = ActiveWorkspaceSection.chapter;
      _selectedItemId = chapter.id;
      _currentLoadedItemId = chapter.id;
      _titleController.text = chapter.title;
      _chapterStartController.text = '';
      _chapterMiddleController.text = '';
      _chapterEndController.text = '';
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
      if (_selectedItemId == chapter.id) {
        _titleController.text = newTitle;
      }
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
          _currentLoadedItemId = null;
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
        _currentLoadedItemId = section.id;
        _titleController.text = section.title;
        _customContentController.text = '';
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
      if (_selectedItemId == section.id) {
        _titleController.text = newTitle;
      }
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
          _currentLoadedItemId = null;
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
        if (_activeSection == ActiveWorkspaceSection.generalIdea && _currentLoadedItemId != 'general_idea') {
          _currentLoadedItemId = 'general_idea';
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

        // Main Pure Digital Paper Pane
        final mainEditorWidget = _buildPureDigitalPaperPane(
          project: project,
          arcs: arcs,
          chapters: chapters,
          customSections: customSections,
          isWide: isWide,
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
          // Mobile Minimalist Canvas with Drawer
          return Scaffold(
            drawer: Drawer(
              child: SafeArea(child: sidebarWidget),
            ),
            body: SafeArea(
              child: mainEditorWidget,
            ),
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
                      _currentLoadedItemId = null;
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
                      const Icon(Icons.timeline_outlined, size: 16, color: AppColors.amberGold),
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
                        _currentLoadedItemId = null;
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
                        _currentLoadedItemId = null;
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
                        _currentLoadedItemId = null;
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

  // --- Main Pure Digital Paper Pane (Notes & Pure Writer Style) ---

  Widget _buildPureDigitalPaperPane({
    required Project project,
    required List<Arc> arcs,
    required List<Chapter> chapters,
    required List<CustomSection> customSections,
    required bool isWide,
  }) {
    switch (_activeSection) {
      case ActiveWorkspaceSection.generalIdea:
        return _buildPureGeneralIdea(isWide: isWide);

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
        return _buildPureArc(arc: arc, isWide: isWide);

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
        return _buildPureChapter(chapter: chapter, isWide: isWide);

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
        return _buildPureCustomSection(section: section, isWide: isWide);
    }
  }

  // 1. Pure General Idea (Borderless Notes Canvas)
  Widget _buildPureGeneralIdea({required bool isWide}) {
    final words = _getWordCount(_generalIdeaController.text);

    return Column(
      children: [
        _buildCanvasTopStrip(
          isWide: isWide,
          wordCountText: '$words words',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48.0 : 20.0,
              vertical: 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Idea',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _generalIdeaController,
                      maxLines: null,
                      minLines: 22,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Start writing your general idea piece by piece...\n\nPremise, world rules, character thoughts, and raw brainstorming. The whole space is yours to write without boundaries.',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onGeneralIdeaChanged,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Pure Arc (Title at Top of Paper, Borderless Body)
  Widget _buildPureArc({required Arc arc, required bool isWide}) {
    if (_currentLoadedItemId != arc.id) {
      _currentLoadedItemId = arc.id;
      _titleController.text = arc.title;
      _arcContentController.text = arc.content;
    }

    final words = _getWordCount(_arcContentController.text);

    return Column(
      children: [
        _buildCanvasTopStrip(
          isWide: isWide,
          wordCountText: '$words words',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48.0 : 20.0,
              vertical: 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline Editable Title right on the paper
                    TextField(
                      controller: _titleController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Arc Title...',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onTitleChanged(arc.id, val),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _arcContentController,
                      maxLines: null,
                      minLines: 22,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write everything for this arc here...\n\nOutline the overarching progression, milestones, key conflicts, and character development across this arc.',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onArcContentChanged(arc.id, val),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Pure Chapter (Continuous Notes Canvas with 3 Beats on Single Page)
  Widget _buildPureChapter({required Chapter chapter, required bool isWide}) {
    if (_currentLoadedItemId != chapter.id) {
      _currentLoadedItemId = chapter.id;
      _titleController.text = chapter.title;
      _chapterStartController.text = chapter.startBeat;
      _chapterMiddleController.text = chapter.middleBeat;
      _chapterEndController.text = chapter.endBeat;
    }

    final totalWords = _getWordCount(
        '${_chapterStartController.text} ${_chapterMiddleController.text} ${_chapterEndController.text}');

    return Column(
      children: [
        _buildCanvasTopStrip(
          isWide: isWide,
          wordCountText: '$totalWords words',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48.0 : 20.0,
              vertical: 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline Editable Chapter Title right on the paper
                    TextField(
                      controller: _titleController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Chapter Title...',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onTitleChanged(chapter.id, val),
                    ),
                    const SizedBox(height: 28),

                    // Beat 1: Start
                    _buildBeatHeader('START', 'Hook & Situation Setup', AppColors.emerald),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chapterStartController,
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'How does this chapter open? Write the hook, immediate situation, and setting...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onChapterStartChanged(chapter.id, val),
                    ),
                    const SizedBox(height: 36),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.12),
                    ),
                    const SizedBox(height: 28),

                    // Beat 2: Middle
                    _buildBeatHeader('MIDDLE', 'Main Conflict & Development', AppColors.amberGold),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chapterMiddleController,
                      maxLines: null,
                      minLines: 8,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'What is the core conflict, tension, or obstacle? Write the confrontation, escalation, and developments...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onChapterMiddleChanged(chapter.id, val),
                    ),
                    const SizedBox(height: 36),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.12),
                    ),
                    const SizedBox(height: 28),

                    // Beat 3: End / Cliffhanger
                    _buildBeatHeader('END / CLIFFHANGER', 'Turning Point or Hook', AppColors.crimsonInk),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chapterEndController,
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'How does this chapter conclude? Write the twist, revelation, dramatic exit, or cliffhanger hook...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onChapterEndChanged(chapter.id, val),
                    ),
                    const SizedBox(height: 48),

                    // Add Next Chapter Button
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Next Chapter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _addChapter,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. Pure Custom Section (Borderless Notes Canvas)
  Widget _buildPureCustomSection({required CustomSection section, required bool isWide}) {
    if (_currentLoadedItemId != section.id) {
      _currentLoadedItemId = section.id;
      _titleController.text = section.title;
      _customContentController.text = section.content;
    }

    final words = _getWordCount(_customContentController.text);

    return Column(
      children: [
        _buildCanvasTopStrip(
          isWide: isWide,
          wordCountText: '$words words',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48.0 : 20.0,
              vertical: 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inline Editable Title right on the paper
                    TextField(
                      controller: _titleController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Section Title...',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onTitleChanged(section.id, val),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _customContentController,
                      maxLines: null,
                      minLines: 22,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.8,
                        letterSpacing: 0.15,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write notes, worldbuilding, characters, or rules for this section...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => _onCustomContentChanged(section.id, val),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Clean Beat Subtitle Component ---

  Widget _buildBeatHeader(String tag, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '•  $subtitle',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ],
    );
  }

  // --- Discreet Canvas Top Toolbar Strip ---

  Widget _buildCanvasTopStrip({
    required bool isWide,
    required String wordCountText,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isWide)
            IconButton(
              icon: Icon(
                _isSidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              tooltip: _isSidebarVisible ? 'Zen Mode (Hide Sidebar)' : 'Show Sidebar',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _isSidebarVisible = !_isSidebarVisible;
                });
              },
            )
          else ...[
            Builder(
              builder: (scaffoldContext) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                tooltip: 'Navigation Menu',
                visualDensity: VisualDensity.compact,
                onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 20),
              tooltip: 'Home',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.go('/'),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 13, color: AppColors.emerald.withOpacity(0.85)),
              const SizedBox(width: 4),
              Text(
                'Saved',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                wordCountText,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
