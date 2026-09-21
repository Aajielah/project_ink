import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';

class SceneDialog extends ConsumerStatefulWidget {
  final String universeId;
  final String chapterId;
  final Scene? existingScene;

  const SceneDialog({
    required this.universeId,
    required this.chapterId,
    this.existingScene,
    super.key,
  });

  @override
  ConsumerState<SceneDialog> createState() => _SceneDialogState();
}

class _SceneDialogState extends ConsumerState<SceneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _locationController;

  int _tensionLevel = 5;
  String _selectedStatus = 'Outlined';

  final List<String> _statuses = ['Outlined', 'Drafted', 'Polished'];

  @override
  void initState() {
    super.initState();
    final s = widget.existingScene;
    _titleController = TextEditingController(text: s?.title ?? '');
    _summaryController = TextEditingController(text: s?.summary ?? '');
    _locationController = TextEditingController(text: s?.locationName ?? '');
    _tensionLevel = s?.tensionLevel ?? 5;
    _selectedStatus = s?.status ?? 'Outlined';
    if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'Outlined';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Color _getTensionColor(int level) {
    if (level <= 3) return AppColors.deepTeal;
    if (level <= 6) return AppColors.amberGold;
    if (level <= 8) return Colors.orange;
    return AppColors.crimsonInk;
  }

  String _getTensionDescription(int level) {
    if (level <= 2) return 'Quiet & Reflective (Lull)';
    if (level <= 4) return 'Rising Curiosity & Subtext';
    if (level <= 6) return 'Moderate Conflict & Obstacles';
    if (level <= 8) return 'High Jeopardy & Suspense';
    return 'Maximum Stakes & Climax!';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(outlineRepositoryProvider);

    if (widget.existingScene != null) {
      await repo.updateScene(
        id: widget.existingScene!.id,
        title: _titleController.text,
        summary: _summaryController.text.isEmpty ? null : _summaryController.text,
        locationName: _locationController.text.isEmpty ? null : _locationController.text,
        tensionLevel: _tensionLevel,
        status: _selectedStatus,
      );
    } else {
      await repo.createScene(
        chapterId: widget.chapterId,
        universeId: widget.universeId,
        title: _titleController.text,
        summary: _summaryController.text.isEmpty ? null : _summaryController.text,
        locationName: _locationController.text.isEmpty ? null : _locationController.text,
        tensionLevel: _tensionLevel,
        status: _selectedStatus,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingScene != null;
    final tensionColor = _getTensionColor(_tensionLevel);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                          color: tensionColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.flash_on, color: tensionColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isEditing ? 'Edit Scene Card' : 'New Scene Card',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Scene Beat Title *',
                      hintText: 'e.g. Confrontation at the Iron Bridge',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a scene title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _summaryController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Scene Summary / Conflict',
                      hintText: 'What occurs, what obstacle arises, and how the beat ends...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Setting / Location',
                            hintText: 'e.g. The Catacombs',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          ),
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
                  const SizedBox(height: 20),
                  // Tension Slider Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: tensionColor.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Dramatic Tension',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tensionColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Level $_tensionLevel / 10',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: tensionColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTensionDescription(_tensionLevel),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: tensionColor,
                            thumbColor: tensionColor,
                          ),
                          child: Slider(
                            value: _tensionLevel.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (val) {
                              setState(() => _tensionLevel = val.toInt());
                            },
                          ),
                        ),
                      ],
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
                        label: Text(isEditing ? 'Save Changes' : 'Add Scene'),
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
