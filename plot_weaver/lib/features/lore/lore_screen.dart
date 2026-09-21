import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../database/app_database.dart';
import '../../shared/providers.dart';
import 'lore_form_dialog.dart';
import 'lore_detail_sheet.dart';

class LoreScreen extends ConsumerStatefulWidget {
  final String universeId;

  const LoreScreen({required this.universeId, super.key});

  @override
  ConsumerState<LoreScreen> createState() => _LoreScreenState();
}

class _LoreScreenState extends ConsumerState<LoreScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _filterCategories = [
    'All',
    'Faction',
    'Location',
    'Magic/Tech',
    'History',
    'Culture',
    'Artifact',
    'Religion',
  ];

  void _openCreateDialog([String? category]) {
    showDialog(
      context: context,
      builder: (context) => LoreFormDialog(
        universeId: widget.universeId,
        initialCategory: category != 'All' ? category : null,
      ),
    );
  }

  void _openDetail(LoreEntry entry) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => LoreDetailSheet(
          entry: entry,
          universeId: widget.universeId,
          isDialog: true,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LoreDetailSheet(
          entry: entry,
          universeId: widget.universeId,
          isDialog: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loreAsync = ref.watch(universeLoreEntriesProvider(widget.universeId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('World Lore Codex'),
            const SizedBox(width: 8),
            Tooltip(
              message: 'World Lore Codex: Document factions, locations, magic or technology systems, historical events, cultural traditions, and relics.',
              child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).hintColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Lore Entry',
            onPressed: () => _openCreateDialog(_selectedCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search factions, locations, relics, doctrines...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _filterCategories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    tooltip: cat == 'All' ? 'Show all lore entries' : 'Filter by $cat entries',
                    selected: isSelected,
                    label: Text(cat),
                    avatar: cat != 'All'
                        ? Icon(
                            LoreDetailSheet.getCategoryIcon(cat),
                            size: 16,
                            color: isSelected ? Colors.white : LoreDetailSheet.getCategoryColor(cat),
                          )
                        : null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Content body
          Expanded(
            child: loreAsync.when(
              data: (entries) {
                var filtered = entries;

                if (_selectedCategory != 'All') {
                  filtered = filtered.where((e) => e.category == _selectedCategory).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((e) {
                    final matchTitle = e.title.toLowerCase().contains(_searchQuery);
                    final matchSummary = e.summary?.toLowerCase().contains(_searchQuery) ?? false;
                    final matchContent = e.content?.toLowerCase().contains(_searchQuery) ?? false;
                    final matchTags = e.tags?.toLowerCase().contains(_searchQuery) ?? false;
                    return matchTitle || matchSummary || matchContent || matchTags;
                  }).toList();
                }

                if (entries.isEmpty) {
                  return _buildEmptyState(
                    title: 'The Codex is Empty',
                    subtitle: 'Start forging factions, ancient orders, secret locations, and magic systems.',
                    buttonText: 'Add First Lore Entry',
                    onAction: () => _openCreateDialog(),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No lore entries match your filter.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 600
                            ? 2
                            : 1;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 180,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildLoreCard(item);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading lore: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(_selectedCategory),
        tooltip: 'Create a new world lore entry',
        icon: const Icon(Icons.add),
        label: const Text('New Lore'),
        backgroundColor: AppColors.deepTeal,
      ),
    );
  }

  Widget _buildLoreCard(LoreEntry item) {
    final catColor = LoreDetailSheet.getCategoryColor(item.category);
    final catIcon = LoreDetailSheet.getCategoryIcon(item.category);
    final tagList = item.tags?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [];

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catIcon, size: 14, color: catColor),
                        const SizedBox(width: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  item.summary ?? item.content ?? 'No description provided.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tagList.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (int i = 0; i < tagList.length && i < 2; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '#${tagList[i]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    if (tagList.length > 2)
                      Text(
                        '+${tagList.length - 2}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.deepTeal.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public, color: AppColors.deepTeal, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
