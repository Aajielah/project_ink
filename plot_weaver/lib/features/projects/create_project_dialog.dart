import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers.dart';

class CreateProjectDialog extends ConsumerStatefulWidget {
  final String? initialBookId;

  const CreateProjectDialog({this.initialBookId, super.key});

  @override
  ConsumerState<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  String? _selectedBookId;
  bool _isCreating = false;

  final List<String> _commonGenres = [
    'Fantasy',
    'Sci-Fi',
    'Thriller',
    'Mystery',
    'Romance',
    'Horror',
    'Historical',
    'Literary Fiction',
    'Non-Fiction',
  ];

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.initialBookId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final genre = _genreController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final project = await ref.read(projectRepositoryProvider).createProject(
            name: name,
            genre: genre.isNotEmpty ? genre : 'Fiction',
            bookId: _selectedBookId,
          );

      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(allBooksProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Icon(Icons.auto_stories, color: AppColors.amberGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Project',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Only name and genre needed to start your story architecture.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'e.g. The Starlight Heist',
                  prefixIcon: Icon(Icons.title, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre *',
                  hintText: 'e.g. Sci-Fi, Fantasy, Mystery',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              // Genre quick tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _commonGenres.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(g, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _genreController.text = g;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Optional Book selection
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) return const SizedBox.shrink();
                  return DropdownButtonFormField<String?>(
                    value: _selectedBookId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Book Folder (Optional)',
                      prefixIcon: Icon(Icons.folder_open, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned (Standalone Project)'),
                      ),
                      ...books.map(
                        (b) => DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text('${b.name} (${b.genre})'),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBookId = val);
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isCreating ? null : _submit,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Create & Enter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amberGold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
