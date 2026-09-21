import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import 'lore_form_dialog.dart';

class LoreDetailSheet extends ConsumerWidget {
  final LoreEntry entry;
  final String universeId;

  const LoreDetailSheet({
    required this.entry,
    required this.universeId,
    super.key,
  });

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Faction':
        return AppColors.deepTeal;
      case 'Location':
        return AppColors.emeraldGreen;
      case 'Magic/Tech':
        return AppColors.violetLore;
      case 'History':
        return AppColors.goldenHour;
      case 'Culture':
        return AppColors.crimsonArc;
      case 'Artifact':
        return const Color(0xFFE0A96D);
      case 'Religion':
        return const Color(0xFF7E8CE0);
      default:
        return AppColors.deepTeal;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Faction':
        return Icons.shield_outlined;
      case 'Location':
        return Icons.place_outlined;
      case 'Magic/Tech':
        return Icons.auto_awesome_outlined;
      case 'History':
        return Icons.menu_book_outlined;
      case 'Culture':
        return Icons.groups_outlined;
      case 'Artifact':
        return Icons.diamond_outlined;
      case 'Religion':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.public;
    }
  }

  void _edit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LoreFormDialog(
        universeId: universeId,
        entryToEdit: entry,
      ),
    ).then((updated) {
      if (updated == true && context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lore Entry?'),
        content: Text('Are you sure you want to delete "${entry.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonArc),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(loreRepositoryProvider).deleteLoreEntry(entry.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${entry.title}"')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catColor = getCategoryColor(entry.category);
    final catIcon = getCategoryIcon(entry.category);
    final tagList = entry.tags?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(catIcon, color: catColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Lore',
                    onPressed: () => _edit(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.crimsonArc),
                    tooltip: 'Delete Lore',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Summary callout if present
                    if (entry.summary != null && entry.summary!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: catColor.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: catColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.summary!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tags chips
                    if (tagList.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: tagList.map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Content text
                    Text(
                      'Codex Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (entry.content != null && entry.content!.isNotEmpty)
                      SelectableText(
                        entry.content!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      )
                    else
                      Text(
                        'No detailed notes recorded yet for this entry.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
