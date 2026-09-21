import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';

enum ConvertTarget { scene, character, lore }

class ConvertSparkDialog extends ConsumerStatefulWidget {
  final IdeaSpark spark;
  final String universeId;

  const ConvertSparkDialog({
    required this.spark,
    required this.universeId,
    super.key,
  });

  @override
  ConsumerState<ConvertSparkDialog> createState() => _ConvertSparkDialogState();
}

class _ConvertSparkDialogState extends ConsumerState<ConvertSparkDialog> {
  late ConvertTarget _target;

  // Scene fields
  String? _selectedChapterId;
  late final TextEditingController _sceneTitleController;
  int _tensionLevel = 5;

  // Character fields
  late final TextEditingController _characterNameController;
  String _characterRole = 'Protagonist';
  String _characterArchetype = 'The Hero / Chosen One';

  // Lore fields
  late final TextEditingController _loreTitleController;
  String _loreCategory = 'Faction';

  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    // Pre-select target based on spark category
    if (widget.spark.category == 'Dialogue' || widget.spark.category == 'Scene Idea') {
      _target = ConvertTarget.scene;
    } else if (widget.spark.category == 'Character Quirk') {
      _target = ConvertTarget.character;
    } else if (widget.spark.category == 'World Lore') {
      _target = ConvertTarget.lore;
    } else {
      _target = ConvertTarget.scene;
    }

    final firstLine = widget.spark.content.split('\n').first;
    final snippet = firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;

    _sceneTitleController = TextEditingController(text: snippet);
    _characterNameController = TextEditingController(text: snippet);
    _loreTitleController = TextEditingController(text: snippet);
  }

  @override
  void dispose() {
    _sceneTitleController.dispose();
    _characterNameController.dispose();
    _loreTitleController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    setState(() => _isConverting = true);
    try {
      if (_target == ConvertTarget.scene) {
        if (_selectedChapterId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a chapter for the scene.')),
          );
          setState(() => _isConverting = false);
          return;
        }

        final outlineRepo = ref.read(outlineRepositoryProvider);
        await outlineRepo.createScene(
          chapterId: _selectedChapterId!,
          universeId: widget.universeId,
          title: _sceneTitleController.text.trim().isEmpty ? 'New Scene' : _sceneTitleController.text.trim(),
          summary: widget.spark.content,
          tensionLevel: _tensionLevel,
        );
      } else if (_target == ConvertTarget.character) {
        final charRepo = ref.read(characterRepositoryProvider);
        await charRepo.createCharacter(
          universeId: widget.universeId,
          name: _characterNameController.text.trim().isEmpty ? 'New Character' : _characterNameController.text.trim(),
          role: _characterRole,
          archetype: _characterArchetype,
          backstory: widget.spark.content,
        );
      } else if (_target == ConvertTarget.lore) {
        final loreRepo = ref.read(loreRepositoryProvider);
        await loreRepo.createLoreEntry(
          universeId: widget.universeId,
          title: _loreTitleController.text.trim().isEmpty ? 'New Lore Entry' : _loreTitleController.text.trim(),
          category: _loreCategory,
          content: widget.spark.content,
        );
      }

      // Mark spark as converted
      final sparkRepo = ref.read(sparkRepositoryProvider);
      await sparkRepo.markConverted(widget.spark.id, true);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Converted into ${_target == ConvertTarget.scene ? "Scene" : _target == ConvertTarget.character ? "Character" : "Lore Entry"}!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(universeChaptersProvider(widget.universeId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 460;
            return Padding(
              padding: EdgeInsets.all(isNarrow ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldenHour.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.goldenHour, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Convert Idea Spark',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Original spark preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORIGINAL NOTE (${widget.spark.category.toUpperCase()}):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.spark.content,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'What do you want to transform this into?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Segmented target picker
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ConvertTarget>(
                      segments: isNarrow
                          ? const [
                              ButtonSegment(
                                value: ConvertTarget.scene,
                                label: Text('Scene'),
                              ),
                              ButtonSegment(
                                value: ConvertTarget.character,
                                label: Text('Cast'),
                              ),
                              ButtonSegment(
                                value: ConvertTarget.lore,
                                label: Text('Lore'),
                              ),
                            ]
                          : const [
                              ButtonSegment(
                                value: ConvertTarget.scene,
                                icon: Icon(Icons.movie_creation_outlined, size: 18),
                                label: Text('Scene'),
                              ),
                              ButtonSegment(
                                value: ConvertTarget.character,
                                icon: Icon(Icons.person_outline, size: 18),
                                label: Text('Character'),
                              ),
                              ButtonSegment(
                                value: ConvertTarget.lore,
                                icon: Icon(Icons.public, size: 18),
                                label: Text('World Lore'),
                              ),
                            ],
                      selected: {_target},
                      onSelectionChanged: (selected) {
                        setState(() => _target = selected.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form fields depending on target
                  Expanded(
                    child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_target == ConvertTarget.scene) ...[
                        chaptersAsync.when(
                          data: (chapters) {
                            if (chapters.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No chapters found. Please create a chapter in Outline first.',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              );
                            }
                            _selectedChapterId ??= chapters.first.id;

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedChapterId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Target Chapter *',
                                prefixIcon: Icon(Icons.book_outlined),
                              ),
                              items: chapters.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text('Ch. ${c.chapterNumber}: ${c.title}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedChapterId = val);
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Text('Error: $err'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _sceneTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Scene Title *',
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('Tension Level: '),
                            Text(
                              '$_tensionLevel/10',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _tensionLevel >= 7 ? AppColors.crimsonArc : AppColors.goldenHour,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _tensionLevel.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                activeColor: _tensionLevel >= 7 ? AppColors.crimsonArc : AppColors.goldenHour,
                                onChanged: (v) => setState(() => _tensionLevel = v.round()),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_target == ConvertTarget.character) ...[
                        TextFormField(
                          controller: _characterNameController,
                          decoration: const InputDecoration(
                            labelText: 'Character Name *',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _characterRole,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Protagonist', child: Text('Protagonist')),
                            DropdownMenuItem(value: 'Antagonist', child: Text('Antagonist')),
                            DropdownMenuItem(value: 'Deuteragonist', child: Text('Deuteragonist (Secondary Lead)')),
                            DropdownMenuItem(value: 'Mentor', child: Text('Mentor / Guide')),
                            DropdownMenuItem(value: 'Love Interest', child: Text('Love Interest')),
                            DropdownMenuItem(value: 'Supporting', child: Text('Supporting Character')),
                            DropdownMenuItem(value: 'Minor / Foil', child: Text('Minor / Foil')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _characterRole = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _characterArchetype,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Archetype',
                            prefixIcon: Icon(Icons.psychology_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'The Hero / Chosen One', child: Text('The Hero / Chosen One')),
                            DropdownMenuItem(value: 'The Shadow / Nemesis', child: Text('The Shadow / Nemesis')),
                            DropdownMenuItem(value: 'The Rebel / Outlaw', child: Text('The Rebel / Outlaw')),
                            DropdownMenuItem(value: 'The Sage / Mentor', child: Text('The Sage / Mentor')),
                            DropdownMenuItem(value: 'The Trickster / Rogue', child: Text('The Trickster / Rogue')),
                            DropdownMenuItem(value: 'The Guardian / Protector', child: Text('The Guardian / Protector')),
                            DropdownMenuItem(value: 'The Catalyst', child: Text('The Catalyst')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _characterArchetype = val);
                          },
                        ),
                      ] else if (_target == ConvertTarget.lore) ...[
                        TextFormField(
                          controller: _loreTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Codex Entry Title *',
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _loreCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Faction', child: Text('Faction')),
                            DropdownMenuItem(value: 'Location', child: Text('Location')),
                            DropdownMenuItem(value: 'Magic/Tech', child: Text('Magic/Tech')),
                            DropdownMenuItem(value: 'History', child: Text('History')),
                            DropdownMenuItem(value: 'Culture', child: Text('Culture')),
                            DropdownMenuItem(value: 'Artifact', child: Text('Artifact')),
                            DropdownMenuItem(value: 'Religion', child: Text('Religion')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _loreCategory = val);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isConverting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: _isConverting ? null : _convert,
                      icon: _isConverting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isConverting ? 'Converting...' : 'Convert & Create'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.goldenHour),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  ),
);
  }
}
