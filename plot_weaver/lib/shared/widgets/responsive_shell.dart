import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../../core/constants/app_colors.dart';

class ResponsiveUniverseShell extends ConsumerWidget {
  final Widget child;
  final String universeId;

  const ResponsiveUniverseShell({
    required this.child,
    required this.universeId,
    super.key,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.contains('/outline')) return 1;
    if (location.contains('/characters')) return 2;
    if (location.contains('/lore')) return 3;
    if (location.contains('/scratchpad')) return 4;
    return 0; // dashboard
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/universes/$universeId/dashboard');
        break;
      case 1:
        context.go('/universes/$universeId/outline');
        break;
      case 2:
        context.go('/universes/$universeId/characters');
        break;
      case 3:
        context.go('/universes/$universeId/lore');
        break;
      case 4:
        context.go('/universes/$universeId/scratchpad');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUniverseAsync = ref.watch(activeUniverseProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final selectedIndex = _calculateSelectedIndex(context);

    return activeUniverseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error loading universe: $err')),
      ),
      data: (universe) {
        final title = universe?.title ?? 'Story Universe';
        final genre = universe?.genre ?? '';
        final coverColor = AppColors.getCoverAccent(universe?.coverColor ?? 'amber');

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => _onDestinationSelected(context, index),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'Switch Story Universe',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.go('/'),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: coverColor.withOpacity(0.18),
                            border: Border.all(color: coverColor, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_stories, color: coverColor, size: 24),
                        ),
                      ],
                    ),
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Tooltip(
                        message: 'Overview: Universe dashboard, stats & story modules',
                        child: Icon(Icons.dashboard_outlined),
                      ),
                      selectedIcon: Tooltip(
                        message: 'Overview: Universe dashboard, stats & story modules',
                        child: Icon(Icons.dashboard),
                      ),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(
                        message: 'Outline: Acts, chapters, scene beats & tension meter',
                        child: Icon(Icons.auto_stories_outlined),
                      ),
                      selectedIcon: Tooltip(
                        message: 'Outline: Acts, chapters, scene beats & tension meter',
                        child: Icon(Icons.auto_stories),
                      ),
                      label: Text('Outline'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(
                        message: 'Characters: Psychological dossiers, motivations & relationship web',
                        child: Icon(Icons.people_alt_outlined),
                      ),
                      selectedIcon: Tooltip(
                        message: 'Characters: Psychological dossiers, motivations & relationship web',
                        child: Icon(Icons.people_alt),
                      ),
                      label: Text('Characters'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(
                        message: 'Lore: World Codex for factions, locations & magic rules',
                        child: Icon(Icons.public_outlined),
                      ),
                      selectedIcon: Tooltip(
                        message: 'Lore: World Codex for factions, locations & magic rules',
                        child: Icon(Icons.public),
                      ),
                      label: Text('Lore'),
                    ),
                    NavigationRailDestination(
                      icon: Tooltip(
                        message: 'Sparks: Frictionless idea capture scratchpad with 1-click weaving',
                        child: Icon(Icons.lightbulb_outline),
                      ),
                      selectedIcon: Tooltip(
                        message: 'Sparks: Frictionless idea capture scratchpad with 1-click weaving',
                        child: Icon(Icons.lightbulb),
                      ),
                      label: Text('Sparks'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Tooltip(
                              message: 'Genre: ${genre.toUpperCase()}',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: coverColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  genre.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: coverColor,
                                  ),
                                ),
                              ),
                            ),
                            if (universe?.linkedProjectInkName != null) ...[
                              Builder(
                                builder: (context) {
                                  final inkName = universe!.linkedProjectInkName!;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 10),
                                      Tooltip(
                                        message: 'Synced with Project Ink manuscript: "$inkName"',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.emerald.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.link, size: 12, color: AppColors.emerald),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ink: $inkName',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.emerald,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                            const Spacer(),
                            Tooltip(
                              message: 'Use sidebar tabs to navigate Overview, Outline, Cast, Lore, and Sparks',
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Switch Story Universe (Gallery)',
                              icon: const Icon(Icons.grid_view_rounded),
                              onPressed: () => context.go('/'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile / Small screen layout
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Switch Story Universe',
              onPressed: () => context.go('/'),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  genre,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                tooltip: 'Story Bible: Tap bottom tabs to switch between Overview, Outline, Cast, Lore, and Sparks.',
                onPressed: () {},
              ),
            ],
          ),
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Overview',
                tooltip: 'Overview: Universe dashboard, stats & story modules',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_stories_outlined),
                selectedIcon: Icon(Icons.auto_stories),
                label: 'Outline',
                tooltip: 'Outline: Acts, chapters, scene beats & tension pacing',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: 'Cast',
                tooltip: 'Cast: Character dossiers, flaws & relationships',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public),
                label: 'Lore',
                tooltip: 'Lore: World codex, factions & magic rules',
              ),
              NavigationDestination(
                icon: Icon(Icons.lightbulb_outline),
                selectedIcon: Icon(Icons.lightbulb),
                label: 'Sparks',
                tooltip: 'Sparks: Idea scratchpad with 1-click conversion',
              ),
            ],
          ),
        );
      },
    );
  }
}
