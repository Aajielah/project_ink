import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';

class LoreFormDialog extends ConsumerStatefulWidget {
  final String universeId;
  final LoreEntry? entryToEdit;
  final String? initialCategory;
  final String? initialContent;

  const LoreFormDialog({
    required this.universeId,
    this.entryToEdit,
    this.initialCategory,
    this.initialContent,
    super.key,
  });

  @override
  ConsumerState<LoreFormDialog> createState() => _LoreFormDialogState();
}

class _LoreFormDialogState extends ConsumerState<LoreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Faction', 'icon': Icons.shield_outlined, 'color': AppColors.deepTeal},
    {'name': 'Location', 'icon': Icons.place_outlined, 'color': AppColors.emeraldGreen},
    {'name': 'Magic/Tech', 'icon': Icons.auto_awesome_outlined, 'color': AppColors.violetLore},
    {'name': 'History', 'icon': Icons.menu_book_outlined, 'color': AppColors.goldenHour},
    {'name': 'Culture', 'icon': Icons.groups_outlined, 'color': AppColors.crimsonArc},
    {'name': 'Artifact', 'icon': Icons.diamond_outlined, 'color': Color(0xFFE0A96D)},
    {'name': 'Religion', 'icon': Icons.wb_sunny_outlined, 'color': Color(0xFF7E8CE0)},
  ];

  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entryToEdit;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _summaryController = TextEditingController(text: entry?.summary ?? '');
    _contentController = TextEditingController(text: entry?.content ?? widget.initialContent ?? '');
    _tagsController = TextEditingController(text: entry?.tags ?? '');
    _selectedCategory = entry?.category ?? widget.initialCategory ?? _categories.first['name'] as String;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(loreRepositoryProvider);
      if (widget.entryToEdit != null) {
        await repo.updateLoreEntry(
          id: widget.entryToEdit!.id,
          title: _titleController.text.trim(),
          category: _selectedCategory,
          summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
          content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
          tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        );
      } else {
        await repo.createLoreEntry(
          universeId: widget.universeId,
          title: _titleController.text.trim(),
          category: _selectedCategory,
          summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
          content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
          tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving lore entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entryToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.deepTeal.withOpacity(0.15),
                      child: const Icon(Icons.public, color: AppColors.deepTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Edit Lore Entry' : 'New World Lore Entry',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Entry Title *',
                            hintText: 'e.g. The Silver Syndicate, Order of the Eclipse, Obsidian Citadel',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),

                        // Category Selector
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories.map((cat) {
                            final name = cat['name'] as String;
                            final icon = cat['icon'] as IconData;
                            final color = cat['color'] as Color;
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  Icon(icon, size: 18, color: color),
                                  const SizedBox(width: 10),
                                  Text(name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Summary
                        TextFormField(
                          controller: _summaryController,
                          decoration: const InputDecoration(
                            labelText: 'Quick Summary / Logline',
                            hintText: 'A concise 1-2 sentence description for quick memory reference',
                            prefixIcon: Icon(Icons.short_text),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                            hintText: 'e.g. forbidden, northern territory, capital, ancient relic',
                            prefixIcon: Icon(Icons.tag),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Detailed Content / Lore Body
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: 'Full Lore & World Rules (Markdown supported)',
                            hintText: 'History, doctrine, powers, hierarchy, rituals, weaknesses, secrets...',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Entry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
