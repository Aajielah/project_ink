import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';

class CharacterFormDialog extends ConsumerStatefulWidget {
  final String universeId;
  final Character? existingCharacter;

  const CharacterFormDialog({
    required this.universeId,
    this.existingCharacter,
    super.key,
  });

  @override
  ConsumerState<CharacterFormDialog> createState() => _CharacterFormDialogState();
}

class _CharacterFormDialogState extends ConsumerState<CharacterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _aliasController;
  late TextEditingController _ageController;
  late TextEditingController _occupationController;
  late TextEditingController _motivationController;
  late TextEditingController _flawController;
  late TextEditingController _conflictController;
  late TextEditingController _backstoryController;
  late TextEditingController _notesController;

  late String _selectedRole;
  late String _selectedArchetype;
  late String _selectedArcStage;
  late String _selectedColor;

  final List<String> _roles = [
    'Protagonist',
    'Antagonist',
    'Supporting',
    'Mentor',
    'Foil',
  ];

  final List<String> _archetypes = [
    'The Rebel',
    'The Chosen One',
    'The Sage / Mentor',
    'The Shadow',
    'The Trickster',
    'The Herald',
    'The Caregiver',
    'The Outlaw',
    'The Explorer',
    'The Ruler',
  ];

  final List<String> _arcStages = [
    'Introduction (Status Quo)',
    'Inciting Catalyst',
    'Midpoint Shift',
    'Dark Night of the Soul',
    'Climax & Revelation',
    'Transformation / Resolution',
  ];

  final List<String> _colors = ['teal', 'amber', 'crimson', 'violet', 'blue', 'emerald'];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCharacter;
    _nameController = TextEditingController(text: c?.name ?? '');
    _aliasController = TextEditingController(text: c?.alias ?? '');
    _ageController = TextEditingController(text: c?.age ?? '');
    _occupationController = TextEditingController(text: c?.occupation ?? '');
    _motivationController = TextEditingController(text: c?.motivation ?? '');
    _flawController = TextEditingController(text: c?.flaw ?? '');
    _conflictController = TextEditingController(text: c?.internalConflict ?? '');
    _backstoryController = TextEditingController(text: c?.backstory ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');

    _selectedRole = c?.role ?? 'Protagonist';
    if (!_roles.contains(_selectedRole)) _selectedRole = 'Protagonist';

    _selectedArchetype = c?.archetype ?? _archetypes.first;
    if (!_archetypes.contains(_selectedArchetype)) _selectedArchetype = _archetypes.first;

    _selectedArcStage = c?.arcStage ?? _arcStages.first;
    if (!_arcStages.contains(_selectedArcStage)) _selectedArcStage = _arcStages.first;

    _selectedColor = c?.avatarColor ?? 'teal';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _motivationController.dispose();
    _flawController.dispose();
    _conflictController.dispose();
    _backstoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(characterRepositoryProvider);

    if (widget.existingCharacter != null) {
      await repo.updateCharacter(
        id: widget.existingCharacter!.id,
        name: _nameController.text,
        alias: _aliasController.text.isEmpty ? null : _aliasController.text,
        role: _selectedRole,
        archetype: _selectedArchetype,
        age: _ageController.text.isEmpty ? null : _ageController.text,
        occupation: _occupationController.text.isEmpty ? null : _occupationController.text,
        motivation: _motivationController.text.isEmpty ? null : _motivationController.text,
        flaw: _flawController.text.isEmpty ? null : _flawController.text,
        internalConflict: _conflictController.text.isEmpty ? null : _conflictController.text,
        backstory: _backstoryController.text.isEmpty ? null : _backstoryController.text,
        arcStage: _selectedArcStage,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        avatarColor: _selectedColor,
      );
    } else {
      await repo.createCharacter(
        universeId: widget.universeId,
        name: _nameController.text,
        alias: _aliasController.text.isEmpty ? null : _aliasController.text,
        role: _selectedRole,
        archetype: _selectedArchetype,
        age: _ageController.text.isEmpty ? null : _ageController.text,
        occupation: _occupationController.text.isEmpty ? null : _occupationController.text,
        motivation: _motivationController.text.isEmpty ? null : _motivationController.text,
        flaw: _flawController.text.isEmpty ? null : _flawController.text,
        internalConflict: _conflictController.text.isEmpty ? null : _conflictController.text,
        backstory: _backstoryController.text.isEmpty ? null : _backstoryController.text,
        arcStage: _selectedArcStage,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        avatarColor: _selectedColor,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCharacter != null;
    final color = AppColors.getCoverAccent(_selectedColor);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 750),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            return Padding(
              padding: EdgeInsets.all(isNarrow ? 18.0 : 26.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: color.withOpacity(0.2),
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Character Dossier' : 'New Character Dossier',
                              style: TextStyle(
                                fontSize: isNarrow ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name and Alias
                      if (isNarrow) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Character Name *',
                            hintText: 'e.g. Kaelen Vance',
                          ),
                          onChanged: (v) => setState(() {}),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a character name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _aliasController,
                          decoration: const InputDecoration(
                            labelText: 'Alias / Moniker',
                            hintText: 'e.g. The Silver Ghost',
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Character Name *',
                                  hintText: 'e.g. Kaelen Vance',
                                ),
                                onChanged: (v) => setState(() {}),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a character name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _aliasController,
                                decoration: const InputDecoration(
                                  labelText: 'Alias / Moniker',
                                  hintText: 'e.g. The Silver Ghost',
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Role and Archetype
                      if (isNarrow) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(labelText: 'Story Role'),
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedArchetype,
                          decoration: const InputDecoration(labelText: 'Archetype'),
                          items: _archetypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedArchetype = val);
                          },
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedRole,
                                decoration: const InputDecoration(labelText: 'Story Role'),
                                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedArchetype,
                                decoration: const InputDecoration(labelText: 'Archetype'),
                                items: _archetypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedArchetype = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Age & Occupation
                      if (isNarrow) ...[
                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Age / Appearance',
                            hintText: 'e.g. 28, weathered',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _occupationController,
                          decoration: const InputDecoration(
                            labelText: 'Occupation / Status',
                            hintText: 'e.g. High Archivist',
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: const InputDecoration(
                                  labelText: 'Age / Appearance',
                                  hintText: 'e.g. 28, weathered',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _occupationController,
                                decoration: const InputDecoration(
                                  labelText: 'Occupation / Status',
                                  hintText: 'e.g. High Archivist',
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                  // Psychology & Flaws
                  TextFormField(
                    controller: _motivationController,
                    decoration: const InputDecoration(
                      labelText: 'Core Motivation (What they want)',
                      hintText: 'e.g. Avenge their fallen order and break the curse',
                      prefixIcon: Icon(Icons.star_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _flawController,
                    decoration: const InputDecoration(
                      labelText: 'Fatal Flaw / Blindspot',
                      hintText: 'e.g. Severe trust issues; prefers isolation over alliance',
                      prefixIcon: Icon(Icons.heart_broken_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _conflictController,
                    decoration: const InputDecoration(
                      labelText: 'Internal Conflict (Want vs Need)',
                      hintText: 'e.g. Wants isolation, but needs connection to survive',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Arc Stage
                  DropdownButtonFormField<String>(
                    initialValue: _selectedArcStage,
                    decoration: const InputDecoration(labelText: 'Current Character Arc Stage'),
                    items: _arcStages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedArcStage = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Backstory
                  TextFormField(
                    controller: _backstoryController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Backstory & History',
                      hintText: 'Childhood origins, critical life-altering events, and secrets...',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Avatar Color Accent
                  Row(
                    children: [
                      const Text(
                        'Badge Accent:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: _colors.map((c) {
                          final isSelected = _selectedColor == c;
                          final accent = AppColors.getCoverAccent(c);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons
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
                        label: Text(isEditing ? 'Save Dossier' : 'Create Character'),
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
