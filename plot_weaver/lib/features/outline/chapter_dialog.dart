import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';

class ChapterDialog extends ConsumerStatefulWidget {
  final String universeId;
  final Chapter? existingChapter;
  final String? defaultAct;

  const ChapterDialog({
    required this.universeId,
    this.existingChapter,
    this.defaultAct,
    super.key,
  });

  @override
  ConsumerState<ChapterDialog> createState() => _ChapterDialogState();
}

class _ChapterDialogState extends ConsumerState<ChapterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _objectiveController;
  late TextEditingController _wordsController;
  late TextEditingController _notesController;

  late String _selectedAct;
  late String _selectedStatus;

  final List<String> _acts = [
    'Prologue',
    'Act I',
    'Act IIA',
    'Act IIB',
    'Act III',
    'Epilogue',
  ];

  final List<String> _statuses = [
    'Idea',
    'Outlined',
    'Drafting',
    'Revised',
    'Done',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingChapter;
    _titleController = TextEditingController(text: c?.title ?? '');
    _objectiveController = TextEditingController(text: c?.objective ?? '');
    _wordsController = TextEditingController(
      text: c != null ? c.estimatedWordCount.toString() : '2500',
    );
    _notesController = TextEditingController(text: c?.notes ?? '');

    _selectedAct = c?.act ?? widget.defaultAct ?? 'Act I';
    if (!_acts.contains(_selectedAct)) _selectedAct = 'Act I';

    _selectedStatus = c?.status ?? 'Outlined';
    if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'Outlined';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _objectiveController.dispose();
    _wordsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(outlineRepositoryProvider);
    final words = int.tryParse(_wordsController.text.trim()) ?? 2500;

    if (widget.existingChapter != null) {
      await repo.updateChapter(
        id: widget.existingChapter!.id,
        title: _titleController.text,
        act: _selectedAct,
        objective: _objectiveController.text.isEmpty ? null : _objectiveController.text,
        estimatedWordCount: words,
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    } else {
      await repo.createChapter(
        universeId: widget.universeId,
        title: _titleController.text,
        act: _selectedAct,
        objective: _objectiveController.text.isEmpty ? null : _objectiveController.text,
        estimatedWordCount: words,
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingChapter != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(26.0),
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
                          color: AppColors.amberGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_stories, color: AppColors.amberGold, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isEditing ? 'Edit Chapter' : 'New Chapter',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAct,
                          decoration: const InputDecoration(labelText: 'Act / Part'),
                          items: _acts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAct = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Chapter Title *',
                      hintText: 'e.g. The Midnight Pursuit',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a chapter title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _objectiveController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Chapter Objective / Story Goal',
                      hintText: 'What fundamentally shifts or changes for the protagonist in this chapter?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _wordsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Est. Word Count',
                            hintText: '2500',
                            suffixText: 'words',
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                              return 'Enter valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Writer Notes',
                      hintText: 'Subtle clues to plant, thematic motifs, or continuity reminders...',
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        label: Text(isEditing ? 'Save Changes' : 'Add Chapter'),
                        onPressed: _save,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
