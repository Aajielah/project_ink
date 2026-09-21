import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../repositories/project_ink_bridge_repository.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';

class UniverseFormDialog extends ConsumerStatefulWidget {
  final Universe? existingUniverse;

  const UniverseFormDialog({this.existingUniverse, super.key});

  @override
  ConsumerState<UniverseFormDialog> createState() => _UniverseFormDialogState();
}

class _UniverseFormDialogState extends ConsumerState<UniverseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _loglineController;
  late TextEditingController _synopsisController;
  String _selectedGenre = 'Fantasy';
  String _selectedColor = 'amber';
  String? _selectedInkId;
  String? _selectedInkName;

  List<ProjectInkBookSummary> _availableInkBooks = [];
  bool _isLoadingInk = true;

  final List<String> _genres = [
    'Fantasy',
    'Sci-Fi',
    'Mystery',
    'Thriller',
    'Historical',
    'Romance',
    'Horror',
    'Adventure',
    'Cyberpunk',
    'Dystopian',
    'Contemporary',
  ];

  final List<String> _colors = ['amber', 'crimson', 'teal', 'violet', 'blue', 'emerald'];

  @override
  void initState() {
    super.initState();
    final u = widget.existingUniverse;
    _titleController = TextEditingController(text: u?.title ?? '');
    _loglineController = TextEditingController(text: u?.logline ?? '');
    _synopsisController = TextEditingController(text: u?.synopsis ?? '');
    _selectedGenre = u?.genre ?? 'Fantasy';
    if (!_genres.contains(_selectedGenre)) {
      _selectedGenre = _genres.first;
    }
    _selectedColor = u?.coverColor ?? 'amber';
    _selectedInkId = u?.linkedProjectInkId;
    _selectedInkName = u?.linkedProjectInkName;

    _loadInkBooks();
  }

  Future<void> _loadInkBooks() async {
    final bridge = ref.read(projectInkBridgeProvider);
    final books = await bridge.fetchAvailableInkBooks();
    if (mounted) {
      setState(() {
        _availableInkBooks = books;
        _isLoadingInk = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _loglineController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(universeRepositoryProvider);

    if (widget.existingUniverse != null) {
      await repo.updateUniverse(
        id: widget.existingUniverse!.id,
        title: _titleController.text,
        genre: _selectedGenre,
        logline: _loglineController.text.isEmpty ? null : _loglineController.text,
        synopsis: _synopsisController.text.isEmpty ? null : _synopsisController.text,
        coverColor: _selectedColor,
        linkedProjectInkId: _selectedInkId,
        linkedProjectInkName: _selectedInkName,
      );
    } else {
      await repo.createUniverse(
        title: _titleController.text,
        genre: _selectedGenre,
        logline: _loglineController.text.isEmpty ? null : _loglineController.text,
        synopsis: _synopsisController.text.isEmpty ? null : _synopsisController.text,
        coverColor: _selectedColor,
        linkedProjectInkId: _selectedInkId,
        linkedProjectInkName: _selectedInkName,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingUniverse != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 460;
            return Padding(
              padding: EdgeInsets.all(isNarrow ? 18.0 : 28.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.getCoverAccent(_selectedColor).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_stories,
                              color: AppColors.getCoverAccent(_selectedColor),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Story Universe' : 'New Story Universe',
                              style: TextStyle(
                                fontSize: isNarrow ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Universe / Book Title *',
                          hintText: 'e.g. Chronicles of Eldoria',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isNarrow) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGenre,
                          decoration: const InputDecoration(labelText: 'Genre'),
                          items: _genres.map((g) {
                            return DropdownMenuItem(value: g, child: Text(g));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGenre = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cover Accent',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _colors.map((c) {
                                final isSelected = _selectedColor == c;
                                final color = AppColors.getCoverAccent(c);
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColor = c),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 2.5)
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedGenre,
                                decoration: const InputDecoration(labelText: 'Genre'),
                                items: _genres.map((g) {
                                  return DropdownMenuItem(value: g, child: Text(g));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGenre = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cover Accent',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _colors.map((c) {
                                      final isSelected = _selectedColor == c;
                                      final color = AppColors.getCoverAccent(c);
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedColor = c),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: isSelected
                                                ? Border.all(color: Colors.white, width: 2.5)
                                                : null,
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(0.5),
                                                      blurRadius: 6,
                                                      spreadRadius: 1,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _loglineController,
                        decoration: const InputDecoration(
                          labelText: 'Logline / Pitch',
                          hintText: 'A one-sentence hook capturing the core conflict...',
                        ),
                      ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _synopsisController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Premise / Synopsis',
                      hintText: 'Detailed summary of the world, conflict, and key themes...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Project Ink Bridge Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(
                        color: _selectedInkId != null
                            ? AppColors.emerald.withOpacity(0.6)
                            : Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 18, color: AppColors.emerald),
                            const SizedBox(width: 8),
                            const Text(
                              'Link to Project Ink Book',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (_selectedInkId != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedInkId = null;
                                    _selectedInkName = null;
                                  });
                                },
                                child: const Text('Unlink', style: TextStyle(color: Colors.redAccent)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingInk)
                          const LinearProgressIndicator()
                        else if (_availableInkBooks.isEmpty)
                          const Text(
                            'No active Project Ink books detected on this device. You can link later.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedInkId,
                            hint: const Text('Select a book from Project Ink'),
                            isExpanded: true,
                            items: _availableInkBooks.map((book) {
                              return DropdownMenuItem(
                                value: book.id,
                                child: Text('${book.name} (${book.writtenWords} words)'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final matched = _availableInkBooks.firstWhere((b) => b.id == val);
                                setState(() {
                                  _selectedInkId = matched.id;
                                  _selectedInkName = matched.name;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(isEditing ? 'Save Changes' : 'Create Universe'),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);
  }
}
