import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import 'convert_spark_dialog.dart';

class ScratchpadScreen extends ConsumerStatefulWidget {
  final String universeId;

  const ScratchpadScreen({required this.universeId, super.key});

  @override
  ConsumerState<ScratchpadScreen> createState() => _ScratchpadScreenState();
}

class _ScratchpadScreenState extends ConsumerState<ScratchpadScreen> {
  final _inputController = TextEditingController();
  String _inputCategory = 'General';
  String _filterCategory = 'All';
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'General',
    'Dialogue',
    'Scene Idea',
    'Character Quirk',
    'World Lore',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dialogue':
        return AppColors.goldenHour;
      case 'Scene Idea':
        return AppColors.crimsonArc;
      case 'Character Quirk':
        return AppColors.emeraldGreen;
      case 'World Lore':
        return AppColors.violetLore;
      default:
        return AppColors.deepTeal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dialogue':
        return Icons.chat_bubble_outline;
      case 'Scene Idea':
        return Icons.movie_creation_outlined;
      case 'Character Quirk':
        return Icons.face_outlined;
      case 'World Lore':
        return Icons.public;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Future<void> _captureSpark() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(sparkRepositoryProvider);
      await repo.createSpark(
        universeId: widget.universeId,
        content: text,
        category: _inputCategory,
      );
      if (mounted) {
        _inputController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving spark: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConvertDialog(IdeaSpark spark) {
    showDialog(
      context: context,
      builder: (context) => ConvertSparkDialog(
        spark: spark,
        universeId: widget.universeId,
      ),
    );
  }

  void _editSpark(IdeaSpark spark) {
    final editController = TextEditingController(text: spark.content);
    String selectedCat = spark.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Idea Spark'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCat,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCat = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Spark Note',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty) {
                  await ref.read(sparkRepositoryProvider).updateSpark(
                        id: spark.id,
                        content: newContent,
                        category: selectedCat,
                      );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSpark(IdeaSpark spark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Spark?'),
        content: const Text('Are you sure you want to discard this idea spark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonArc),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(sparkRepositoryProvider).deleteSpark(spark.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sparksAsync = ref.watch(universeSparksProvider(widget.universeId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Idea Sparks & Scratchpad'),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Idea Scratchpad: Rapidly capture sudden ideas, dialogue snippets, twists, or quirks, then weave them directly into story elements with 1-click.',
              child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Capture Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.violetLore.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.violetLore.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.flash_on, color: AppColors.violetLore, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quick Capture Spark',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category dropdown for new spark
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _inputCategory,
                          icon: const Icon(Icons.arrow_drop_down, size: 18),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(_inputCategory),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _inputCategory = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inputController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'A sudden dialogue retort, character flaw, unexpected plot twist, or world detail...',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Save this idea note to your universe scratchpad',
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _captureSpark,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.bolt, size: 16),
                        label: const Text('Capture Spark'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.violetLore,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                'All',
                'Pinned',
                'Dialogue',
                'Scene Idea',
                'Character Quirk',
                'World Lore',
                'Converted',
              ].map((filter) {
                final isSelected = _filterCategory == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(filter),
                    avatar: filter == 'Pinned'
                        ? const Icon(Icons.push_pin, size: 14, color: AppColors.goldenHour)
                        : filter == 'Converted'
                            ? const Icon(Icons.check_circle_outline, size: 14, color: AppColors.emeraldGreen)
                            : null,
                    onSelected: (selected) {
                      setState(() => _filterCategory = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Sparks Feed
          Expanded(
            child: sparksAsync.when(
              data: (sparks) {
                var filtered = sparks;

                if (_filterCategory == 'Pinned') {
                  filtered = filtered.where((s) => s.isPinned).toList();
                } else if (_filterCategory == 'Converted') {
                  filtered = filtered.where((s) => s.isConverted).toList();
                } else if (_filterCategory != 'All') {
                  filtered = filtered.where((s) => s.category == _filterCategory).toList();
                }

                if (sparks.isEmpty) {
                  return _buildEmptyState();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No sparks match "$_filterCategory"',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final spark = filtered[index];
                    return _buildSparkCard(spark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkCard(IdeaSpark spark) {
    final catColor = _getCategoryColor(spark.category);
    final catIcon = _getCategoryIcon(spark.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: spark.isPinned
              ? AppColors.goldenHour.withOpacity(0.6)
              : Theme.of(context).dividerColor.withOpacity(0.3),
          width: spark.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category badge + pin + actions
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 12, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            spark.category,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ],
                      ),
                    ),
                    if (spark.isConverted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 11, color: AppColors.emeraldGreen),
                            SizedBox(width: 3),
                            Text(
                              'Weaved',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        spark.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: spark.isPinned ? AppColors.goldenHour : null,
                      ),
                      tooltip: spark.isPinned ? 'Unpin' : 'Pin to top',
                      onPressed: () {
                        ref.read(sparkRepositoryProvider).togglePin(spark.id, !spark.isPinned);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => _editSpark(spark),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete',
                      onPressed: () => _deleteSpark(spark),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              spark.content,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 12),
            // Bottom Action: 1-Click Convert
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: 'Convert this spark into a Scene, Character, or Lore entry with 1-click',
                  child: OutlinedButton.icon(
                    onPressed: () => _showConvertDialog(spark),
                    icon: const Icon(Icons.auto_awesome, size: 15, color: AppColors.violetLore),
                    label: const Text('Weave into Story'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: AppColors.violetLore.withOpacity(0.4)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.violetLore.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline, color: AppColors.violetLore, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Idea Sparks Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                'Sudden dialogue lines, character quirks, and plot twists captured above will be stored here until you weave them into your story.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
