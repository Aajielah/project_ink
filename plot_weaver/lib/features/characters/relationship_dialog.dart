import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';

class RelationshipDialog extends ConsumerStatefulWidget {
  final String universeId;
  final Character sourceCharacter;

  const RelationshipDialog({
    required this.universeId,
    required this.sourceCharacter,
    super.key,
  });

  @override
  ConsumerState<RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends ConsumerState<RelationshipDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;

  String? _selectedTargetId;
  String _selectedRelationType = 'Ally';

  final List<String> _relationTypes = [
    'Ally',
    'Rival',
    'Mentor',
    'Sibling / Family',
    'Enemy / Nemesis',
    'Secret Crush / Romance',
    'Bound by Oath',
    'Betrayed By',
    'Former Partner',
    'Foil',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select another character to connect with')),
      );
      return;
    }

    final repo = ref.read(characterRepositoryProvider);
    await repo.createRelationship(
      universeId: widget.universeId,
      sourceCharacterId: widget.sourceCharacter.id,
      targetCharacterId: _selectedTargetId!,
      relationType: _selectedRelationType,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(universeCharactersProvider(widget.universeId));

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
                          color: AppColors.royalBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_outlined, color: AppColors.royalBlue, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Establish Relationship',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Connecting ${widget.sourceCharacter.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Target Character Dropdown
                  charactersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                    data: (characters) {
                      final eligibleTargets = characters
                          .where((c) => c.id != widget.sourceCharacter.id)
                          .toList();

                      if (eligibleTargets.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No other characters exist in this universe yet. Create more cast members first.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        hint: const Text('Select Character to Connect With *'),
                        decoration: const InputDecoration(labelText: 'Target Character'),
                        items: eligibleTargets.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      AppColors.getCoverAccent(c.avatarColor).withOpacity(0.2),
                                  child: Text(
                                    c.name[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getCoverAccent(c.avatarColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${c.name} (${c.role})'),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTargetId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Relation Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelationType,
                    decoration: const InputDecoration(labelText: 'Dynamic / Relationship Type'),
                    items: _relationTypes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRelationType = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Notes
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Relationship Context / History',
                      hintText: 'e.g. Bound by blood oath during the northern rebellion...',
                    ),
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
                        label: const Text('Link Characters'),
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
