import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import '../../core/constants/app_colors.dart';
import 'character_form_dialog.dart';
import 'character_detail_sheet.dart';

class CharactersScreen extends ConsumerStatefulWidget {
  final String universeId;

  const CharactersScreen({required this.universeId, super.key});

  @override
  ConsumerState<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends ConsumerState<CharactersScreen> {
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _roleFilters = [
    'All',
    'Protagonist',
    'Antagonist',
    'Mentor',
    'Supporting',
    'Foil',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCharacter() {
    showDialog(
      context: context,
      builder: (ctx) => CharacterFormDialog(universeId: widget.universeId),
    );
  }

  void _showEditCharacter(Character character) {
    showDialog(
      context: context,
      builder: (ctx) => CharacterFormDialog(
        universeId: widget.universeId,
        existingCharacter: character,
      ),
    );
  }

  void _showCharacterDetail(Character character) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => CharacterDetailSheet(
          universeId: widget.universeId,
          character: character,
          isDialog: true,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CharacterDetailSheet(
          universeId: widget.universeId,
          character: character,
          isDialog: false,
        ),
      );
    }
  }

  void _confirmDeleteCharacter(Character character) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Character?'),
        content: Text(
          'Delete "${character.name}"? All relationships linked to this character will also be removed.',
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
              await ref.read(characterRepositoryProvider).deleteCharacter(character.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(universeCharactersProvider(widget.universeId));

    return Scaffold(
      body: Column(
        children: [
          // Header / Search Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (isNarrow) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search cast...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Add'),
                        onPressed: _showAddCharacter,
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cast, archetype, or flaw...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('New Character'),
                      onPressed: _showAddCharacter,
                    ),
                  ],
                ),
              );
            },
          ),

          // Role Filter Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _roleFilters.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final role = _roleFilters[index];
                final isSelected = _selectedRoleFilter == role;
                return ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRoleFilter = role);
                  },
                );
              },
            ),
          ),

          // Character List / Grid
          Expanded(
            child: charactersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading cast: $err')),
              data: (characters) {
                final filtered = characters.where((c) {
                  final matchesRole =
                      _selectedRoleFilter == 'All' || c.role.toLowerCase() == _selectedRoleFilter.toLowerCase();
                  final matchesSearch = _searchQuery.isEmpty ||
                      c.name.toLowerCase().contains(_searchQuery) ||
                      (c.alias?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (c.archetype?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (c.flaw?.toLowerCase().contains(_searchQuery) ?? false);
                  return matchesRole && matchesSearch;
                }).toList();

                if (characters.isEmpty) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.royalBlue.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.people_alt_rounded,
                                size: 36,
                                color: AppColors.royalBlue,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No Characters Created Yet',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Populate your universe with protagonists, mentors, foils, and antagonists with rich psychological motivations and flaws.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text('Create First Character'),
                              onPressed: _showAddCharacter,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No characters matched your search filters.'),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 3
                        : constraints.maxWidth > 700
                            ? 2
                            : 1;

                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 220,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final character = filtered[index];
                        return _buildCharacterCard(context, character);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, Character character) {
    final accent = AppColors.getCoverAccent(character.avatarColor);
    final roleColor = AppColors.getRoleColor(character.role);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showCharacterDetail(character),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent.withOpacity(0.2),
                    child: Text(
                      character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (character.alias != null)
                          Text(
                            '"${character.alias}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'view') {
                        _showCharacterDetail(character);
                      } else if (val == 'edit') {
                        _showEditCharacter(character);
                      } else if (val == 'delete') {
                        _confirmDeleteCharacter(character);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Dossier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Character'),
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
              const SizedBox(height: 12),
              // Role & Archetype Badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      character.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                  if (character.archetype != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        character.archetype!,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Motivation / Flaw preview
              Expanded(
                child: Text(
                  character.flaw != null
                      ? 'Flaw: ${character.flaw!}'
                      : character.motivation ?? character.backstory ?? 'Tap to flesh out dossier...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 12),
              Row(
                children: [
                  Text(
                    character.arcStage,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amberGold.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
