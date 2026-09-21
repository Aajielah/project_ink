import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';
import 'relationship_dialog.dart';
import 'character_form_dialog.dart';

class CharacterDetailSheet extends ConsumerStatefulWidget {
  final String universeId;
  final Character character;

  const CharacterDetailSheet({
    required this.universeId,
    required this.character,
    super.key,
  });

  @override
  ConsumerState<CharacterDetailSheet> createState() => _CharacterDetailSheetState();
}

class _CharacterDetailSheetState extends ConsumerState<CharacterDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddRelationship() {
    showDialog(
      context: context,
      builder: (ctx) => RelationshipDialog(
        universeId: widget.universeId,
        sourceCharacter: widget.character,
      ),
    );
  }

  void _showEditCharacter() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (ctx) => CharacterFormDialog(
        universeId: widget.universeId,
        existingCharacter: widget.character,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final accent = AppColors.getCoverAccent(c.avatarColor);
    final roleColor = AppColors.getRoleColor(c.role);
    final relationshipsAsync = ref.watch(characterRelationshipsDetailProvider(c.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accent.withOpacity(0.2),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (c.alias != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '("${c.alias}")',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                          if (c.archetype != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.archetype!,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amberGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.arcStage,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: _showEditCharacter,
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Psychology & Conflict'),
              Tab(text: 'Backstory & Notes'),
              Tab(text: 'Relationship Web'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Psychology & Conflict
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.age != null || c.occupation != null) ...[
                        Row(
                          children: [
                            if (c.age != null)
                              _buildInfoChip(Icons.cake_outlined, 'Age: ${c.age!}'),
                            if (c.age != null && c.occupation != null)
                              const SizedBox(width: 12),
                            if (c.occupation != null)
                              _buildInfoChip(Icons.work_outline, c.occupation!),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      _buildTraitCard(
                        context,
                        title: 'CORE MOTIVATION (WHAT THEY DESPERATELY WANT)',
                        content: c.motivation ?? 'No core motivation defined yet.',
                        icon: Icons.star_rounded,
                        color: AppColors.amberGold,
                      ),
                      const SizedBox(height: 14),
                      _buildTraitCard(
                        context,
                        title: 'FATAL FLAW / BLINDSPOT (HOLDING THEM BACK)',
                        content: c.flaw ?? 'No fatal flaw defined yet.',
                        icon: Icons.heart_broken_rounded,
                        color: AppColors.crimsonInk,
                      ),
                      const SizedBox(height: 14),
                      _buildTraitCard(
                        context,
                        title: 'INTERNAL CONFLICT (WANT VS NEED)',
                        content: c.internalConflict ?? 'No internal conflict defined yet.',
                        icon: Icons.sync_alt_rounded,
                        color: AppColors.royalBlue,
                      ),
                    ],
                  ),
                ),

                // Tab 2: Backstory
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BACKSTORY & ORIGINS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          c.backstory ?? 'No backstory written yet.',
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                      if (c.notes != null && c.notes!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'ADDITIONAL WRITER NOTES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            c.notes!,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tab 3: Relationship Web
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'INTERCONNECTED DYNAMICS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.add_link, size: 16),
                            label: const Text('Add Connection'),
                            onPressed: _showAddRelationship,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: relationshipsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('Error: $e')),
                          data: (rels) {
                            if (rels.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.hub_outlined,
                                      size: 40,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No relationships defined yet',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Connect ${c.name} with allies, rivals, mentors, or enemies.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Connection'),
                                      onPressed: _showAddRelationship,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: rels.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                              itemBuilder: (ctx, index) {
                                final item = rels[index];
                                final other = item.otherCharacter;
                                final otherAccent = AppColors.getCoverAccent(other.avatarColor);

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: otherAccent.withOpacity(0.2),
                                          child: Text(
                                            other.name[0],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: otherAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    other.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.royalBlue.withOpacity(0.18),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      item.relationship.relationType.toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.royalBlue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.relationship.description != null &&
                                                  item.relationship.description!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.relationship.description!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.75),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () async {
                                            await ref
                                                .read(characterRepositoryProvider)
                                                .deleteRelationship(item.relationship.id);
                                            ref.invalidate(characterRelationshipsDetailProvider(c.id));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTraitCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
