import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';

class CreateBookDialog extends ConsumerStatefulWidget {
  final Book? existingBook;

  const CreateBookDialog({this.existingBook, super.key});

  @override
  ConsumerState<CreateBookDialog> createState() => _CreateBookDialogState();
}

class _CreateBookDialogState extends ConsumerState<CreateBookDialog> {
  final _nameController = TextEditingController();
  final _genreController = TextEditingController();
  bool _isSaving = false;

  final List<String> _commonGenres = [
    'Fantasy',
    'Sci-Fi',
    'Thriller',
    'Mystery',
    'Romance',
    'Horror',
    'Series / Saga',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingBook != null) {
      _nameController.text = widget.existingBook!.name;
      _genreController.text = widget.existingBook!.genre;
    }
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
        const SnackBar(content: Text('Please enter a book / series name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(bookRepositoryProvider);
      if (widget.existingBook == null) {
        await repo.createBook(
          name: name,
          genre: genre.isNotEmpty ? genre : 'Fiction',
        );
      } else {
        await repo.updateBook(
          id: widget.existingBook!.id,
          name: name,
          genre: genre.isNotEmpty ? genre : 'Fiction',
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving book folder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBook != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                      color: AppColors.royalBlue.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_special, color: AppColors.royalBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Book Folder' : 'New Book Folder',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Group multiple project drafts and volumes under this book.',
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
                  labelText: 'Book / Series Name *',
                  hintText: 'e.g. The Chronicles of Solaria',
                  prefixIcon: Icon(Icons.menu_book, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre *',
                  hintText: 'e.g. Epic Fantasy, Space Opera',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Create Folder'),
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
