import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers.dart';
import '../../database/app_database.dart';
import '../../core/constants/app_colors.dart';
import '../universes/universe_form_dialog.dart';
import '../export/export_dialog.dart';

class UniverseDashboardScreen extends ConsumerWidget {
  final String universeId;

  const UniverseDashboardScreen({required this.universeId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universeAsync = ref.watch(activeUniverseProvider);
    final statsAsync = ref.watch(universeStatsProvider(universeId));

    return universeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (universe) {
        if (universe == null) {
          return const Center(child: Text('Universe not found'));
        }

        final accent = AppColors.getCoverAccent(universe.coverColor);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              universe.genre.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Tooltip(
                                message: 'Export complete Story Bible as formatted Markdown (for Obsidian, Scrivener, Notion)',
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Export Bible'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => ExportDialog(
                                        universeId: universe.id,
                                        universeTitle: universe.title,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Tooltip(
                                message: 'Edit universe title, genre, logline, synopsis, or cover color',
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit Details'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        universe.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (universe.logline != null && universe.logline!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          universe.logline!,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      if (universe.synopsis != null && universe.synopsis!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          universe.synopsis!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats Row / Grid
              statsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const SizedBox(),
                data: (stats) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;
                      if (isNarrow) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          children: [
                            _buildStatCard(
                              context,
                              title: 'Chapters',
                              value: '${stats.chapterCount}',
                              sub: '${stats.totalEstimatedWords} est. words',
                              icon: Icons.auto_stories,
                              color: AppColors.amberGold,
                              tooltip: 'Chapters & scene beats organized across acts',
                            ),
                            _buildStatCard(
                              context,
                              title: 'Characters',
                              value: '${stats.characterCount}',
                              sub: 'Cast members',
                              icon: Icons.people_alt,
                              color: AppColors.royalBlue,
                              tooltip: 'Cast members with psychological dossiers & relations',
                            ),
                            _buildStatCard(
                              context,
                              title: 'World Lore',
                              value: '${stats.loreCount}',
                              sub: 'Codex entries',
                              icon: Icons.public,
                              color: AppColors.deepTeal,
                              tooltip: 'Codex entries for factions, magic, tech & locations',
                            ),
                            _buildStatCard(
                              context,
                              title: 'Idea Sparks',
                              value: '${stats.sparkCount}',
                              sub: 'Captured ideas',
                              icon: Icons.lightbulb,
                              color: AppColors.violetLore,
                              tooltip: 'Raw ideas & dialogue waiting to be woven into story',
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Chapters',
                              value: '${stats.chapterCount}',
                              sub: '${stats.totalEstimatedWords} est. words',
                              icon: Icons.auto_stories,
                              color: AppColors.amberGold,
                              tooltip: 'Chapters & scene beats organized across acts',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Characters',
                              value: '${stats.characterCount}',
                              sub: 'Cast members',
                              icon: Icons.people_alt,
                              color: AppColors.royalBlue,
                              tooltip: 'Cast members with psychological dossiers & relations',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'World Lore',
                              value: '${stats.loreCount}',
                              sub: 'Codex entries',
                              icon: Icons.public,
                              color: AppColors.deepTeal,
                              tooltip: 'Codex entries for factions, magic, tech & locations',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Idea Sparks',
                              value: '${stats.sparkCount}',
                              sub: 'Captured ideas',
                              icon: Icons.lightbulb,
                              color: AppColors.violetLore,
                              tooltip: 'Raw ideas & dialogue waiting to be woven into story',
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Project Ink Bridge Banner
              if (universe.linkedProjectInkId != null) ...[
                _buildInkBridgeCard(context, ref, universe, universe.linkedProjectInkId!, universe.linkedProjectInkName ?? 'Linked Book'),
                const SizedBox(height: 24),
              ] else ...[
                _buildUnlinkedInkCard(context, universe),
                const SizedBox(height: 24),
              ],

              // Story Bible Pillars Navigation Grid
              Row(
                children: [
                  const Text(
                    'Story Bible Modules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'The four core pillars: Outline (plot), Cast (characters), Lore (worldbuilding), and Sparks (ideas).',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth > 900 ? 2 : 1,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: isNarrow ? 2.4 : 2.8,
                    children: [
                      _buildModuleCard(
                        context,
                        title: 'Chapter & Scene Outliner',
                        description: 'Structure acts, chapter goals, word counts, and drag-and-drop scene cards.',
                        icon: Icons.auto_stories_outlined,
                        color: AppColors.amberGold,
                        onTap: () => context.go('/universes/$universeId/outline'),
                      ),
                      _buildModuleCard(
                        context,
                        title: 'Character Dossiers & Relations',
                        description: 'Profiles with archetypes, internal conflicts, flaws, arcs, and relationship matrix.',
                        icon: Icons.people_alt_outlined,
                        color: AppColors.royalBlue,
                        onTap: () => context.go('/universes/$universeId/characters'),
                      ),
                      _buildModuleCard(
                        context,
                        title: 'World Lore Codex',
                        description: 'Factions, magic systems, technology, locations, history, and artifacts.',
                        icon: Icons.public_outlined,
                        color: AppColors.deepTeal,
                        onTap: () => context.go('/universes/$universeId/lore'),
                      ),
                      _buildModuleCard(
                        context,
                        title: 'Idea Sparks & Scratchpad',
                        description: 'Instant brain-dump for sudden dialogue sparks, twists, and 1-tap conversion.',
                        icon: Icons.lightbulb_outline,
                        color: AppColors.violetLore,
                        onTap: () => context.go('/universes/$universeId/scratchpad'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    String? tooltip,
  }) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: card);
    }
    return card;
  }

  Widget _buildInkBridgeCard(
    BuildContext context,
    WidgetRef ref,
    Universe universe,
    String inkBookId,
    String inkBookName,
  ) {
    final bookAsync = ref.watch(linkedInkBookProvider(inkBookId));

    return Card(
      color: AppColors.emerald.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.emerald.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: bookAsync.when(
          loading: () => Row(
            children: [
              const Icon(Icons.link, color: AppColors.emerald),
              const SizedBox(width: 12),
              Text('Linked to Project Ink book "$inkBookName"...'),
            ],
          ),
          error: (e, s) => Row(
            children: [
              const Icon(Icons.link, color: AppColors.emerald),
              const SizedBox(width: 12),
              Text('Linked to Project Ink: $inkBookName'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                  );
                },
                child: const Text('Manage Link'),
              ),
            ],
          ),
          data: (book) {
            if (book == null) {
              return Row(
                children: [
                  const Icon(Icons.link, color: AppColors.emerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Linked to Project Ink book: $inkBookName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                      );
                    },
                    child: const Text('Manage Link'),
                  ),
                ],
              );
            }

            final pct = (book.progressPercentage * 100).toInt();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book, color: AppColors.emerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              book.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PROJECT INK',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${book.writtenWords} / ${book.targetWords} words ($pct%) • ${book.streak} day streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                            );
                          },
                          child: const Text('Manage Link'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book, color: AppColors.emerald, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                book.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PROJECT INK',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${book.writtenWords} / ${book.targetWords} words ($pct% completed) • ${book.streak} day streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                        );
                      },
                      child: const Text('Manage Link'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnlinkedInkCard(BuildContext context, Universe universe) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 550;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: AppColors.emerald, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Connect with Project Ink',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Link this universe to your Project Ink manuscript to view word counts and streak stats.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_link, size: 16),
                      label: const Text('Link Book'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.emerald,
                        side: BorderSide(color: AppColors.emerald.withOpacity(0.5)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link, color: AppColors.emerald, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connect with Project Ink',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Link this universe to your Project Ink manuscript to view word counts and streak stats.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text('Link Book'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emerald,
                    side: BorderSide(color: AppColors.emerald.withOpacity(0.5)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => UniverseFormDialog(existingUniverse: universe),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
