import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../projects/create_project_dialog.dart';
import '../projects/create_book_dialog.dart';
import '../projects/rename_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _collapsedBookIds = {};

  Future<void> _showNewProjectDialog([String? bookId]) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (ctx) => CreateProjectDialog(initialBookId: bookId),
    );

    if (result != null && mounted) {
      context.go('/project/${result.id}');
    }
  }

  Future<void> _showNewBookDialog([Book? existing]) async {
    await showDialog(
      context: context,
      builder: (ctx) => CreateBookDialog(existingBook: existing),
    );
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? All Arcs, Chapters, and Idea notes will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
    }
  }

  Future<void> _confirmDeleteBook(Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book Folder?'),
        content: Text(
          'Delete "${book.name}"? Projects inside this folder will become standalone and will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Folder'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(bookRepositoryProvider).deleteBook(book.id);
    }
  }

  Future<void> _assignProjectToBook(Project project, List<Book> books) async {
    final chosenBookId = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move "${project.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Standalone (No Book Folder)'),
                selected: project.bookId == null,
                onTap: () => Navigator.of(ctx).pop('UNASSIGN'),
              ),
              const Divider(),
              ...books.map(
                (b) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(b.name),
                  subtitle: Text(b.genre),
                  selected: project.bookId == b.id,
                  onTap: () => Navigator.of(ctx).pop(b.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosenBookId != null) {
      await ref.read(projectRepositoryProvider).assignProjectToBook(
            project.id,
            chosenBookId == 'UNASSIGN' ? null : chosenBookId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(allBooksProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.amberGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_stories, color: AppColors.amberGold, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PlotWeaver',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _showNewBookDialog(),
            icon: const Icon(Icons.create_new_folder_outlined, size: 16),
            label: const Text('New Book'),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showNewProjectDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Project'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amberGold,
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading projects: $err')),
        data: (allProjects) {
          if (allProjects.isEmpty) {
            return _buildEmptyState();
          }

          final books = booksAsync.value ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Books / Series Folders
                    if (books.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.folder_special, size: 20, color: AppColors.royalBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Books & Series (${books.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showNewBookDialog(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Book Folder'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...books.map((book) {
                        final bookProjects = allProjects.where((p) => p.bookId == book.id).toList();
                        final isCollapsed = _collapsedBookIds.contains(book.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book Header
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.book, color: AppColors.royalBlue, size: 20),
                                ),
                                title: Text(
                                  book.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.royalBlue.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        book.genre.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.royalBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${bookProjects.length} draft${bookProjects.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      tooltip: 'New Project in this Book',
                                      onPressed: () => _showNewProjectDialog(book.id),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showNewBookDialog(book);
                                        } else if (val == 'delete') {
                                          _confirmDeleteBook(book);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit Book'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Text('Delete Folder', style: TextStyle(color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                                      onPressed: () {
                                        setState(() {
                                          if (isCollapsed) {
                                            _collapsedBookIds.remove(book.id);
                                          } else {
                                            _collapsedBookIds.add(book.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Book Contained Projects
                              if (!isCollapsed) ...[
                                if (bookProjects.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                    child: Text(
                                      'No projects in this book folder yet. Tap "+" above to add one.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Column(
                                      children: bookProjects
                                          .map((p) => _buildProjectCard(p, books, isNested: true))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Standalone / All Projects Section
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 20, color: AppColors.amberGold),
                        const SizedBox(width: 8),
                        Text(
                          books.isEmpty ? 'All Projects (${allProjects.length})' : 'Standalone Projects',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Builder(
                      builder: (context) {
                        final standaloneProjects =
                            books.isEmpty ? allProjects : allProjects.where((p) => p.bookId == null).toList();

                        if (standaloneProjects.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'All projects are organized inside Book folders.',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: standaloneProjects
                              .map((p) => _buildProjectCard(p, books, isNested: false))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.amberGold.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories, size: 40, color: AppColors.amberGold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to Begin Your Story?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Create a project with just a name and genre. Your General Idea canvas, Arcs, and 3-Beat Chapter Outliner will be set up automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => _showNewProjectDialog(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Project', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amberGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project, List<Book> books, {required bool isNested}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/project/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amberGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article_outlined, color: AppColors.amberGold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            project.genre.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepTeal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to open workspace',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) async {
                  if (val == 'open') {
                    context.go('/project/${project.id}');
                  } else if (val == 'rename') {
                    final newTitle = await RenameDialog.show(
                      context,
                      currentTitle: project.name,
                      headingType: 'Project',
                    );
                    if (newTitle != null) {
                      await ref.read(projectRepositoryProvider).updateProjectInfo(
                            id: project.id,
                            name: newTitle,
                            genre: project.genre,
                            bookId: project.bookId,
                          );
                    }
                  } else if (val == 'move') {
                    await _assignProjectToBook(project, books);
                  } else if (val == 'delete') {
                    await _confirmDeleteProject(project);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.login, size: 18),
                        SizedBox(width: 8),
                        Text('Enter Workspace'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Rename Project'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        Icon(Icons.drive_file_move_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Move to Book...'),
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
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
