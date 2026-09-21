import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';
import 'universe_form_dialog.dart';

class UniversesScreen extends ConsumerWidget {
  const UniversesScreen({super.key});

  void _showFormDialog(BuildContext context, [Universe? universe]) {
    showDialog(
      context: context,
      builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Universe universe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story Universe?'),
        content: Text(
          'Are you sure you want to delete "${universe.title}"? All associated characters, chapters, lore, and notes will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimsonInk),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(universeRepositoryProvider).deleteUniverse(universe.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universesAsync = ref.watch(allUniversesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.amberGold.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories, color: AppColors.amberGold, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('PlotWeaver'),
            if (MediaQuery.of(context).size.width >= 500) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amberGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'STORY BIBLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberGold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MediaQuery.of(context).size.width < 500
                ? IconButton.filled(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'New Universe',
                    onPressed: () => _showFormDialog(context),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Universe'),
                    onPressed: () => _showFormDialog(context),
                  ),
          ),
        ],
      ),
      body: universesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading story universes: $err')),
        data: (universes) {
          if (universes.isEmpty) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.amberGold.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: AppColors.amberGold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Story Bible is Empty',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create your first Story Universe to weave character dossiers, chapter outlines, relationship webs, and world lore.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Story Universe'),
                        onPressed: () => _showFormDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 3
                  : constraints.maxWidth > 700
                      ? 2
                      : 1;

              final isNarrow = constraints.maxWidth < 600;

              return GridView.builder(
                padding: EdgeInsets.all(isNarrow ? 16 : 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  mainAxisExtent: 225,
                ),
                itemCount: universes.length,
                itemBuilder: (context, index) {
                  final u = universes[index];
                  final accent = AppColors.getCoverAccent(u.coverColor);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ref.read(activeUniverseIdProvider.notifier).state = u.id;
                      context.go('/universes/${u.id}/dashboard');
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 6, color: accent),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        u.genre.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showFormDialog(context, u);
                                        } else if (val == 'delete') {
                                          _confirmDelete(context, ref, u);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit Universe'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  u.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  u.logline ?? u.synopsis ?? 'No premise specified.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    if (u.linkedProjectInkName != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.link, size: 12, color: AppColors.emerald),
                                            const SizedBox(width: 4),
                                            Text(
                                              u.linkedProjectInkName!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.emerald,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
