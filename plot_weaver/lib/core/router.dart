import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/universes/universes_screen.dart';
import '../features/dashboard/universe_dashboard_screen.dart';
import '../features/outline/outline_screen.dart';
import '../features/characters/characters_screen.dart';
import '../features/lore/lore_screen.dart';
import '../features/scratchpad/scratchpad_screen.dart';
import '../shared/widgets/responsive_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const UniversesScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final universeId = state.pathParameters['id'] ?? '';
        return ResponsiveUniverseShell(
          universeId: universeId,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/universes/:id/dashboard',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return UniverseDashboardScreen(universeId: id);
          },
        ),
        GoRoute(
          path: '/universes/:id/outline',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OutlineScreen(universeId: id);
          },
        ),
        GoRoute(
          path: '/universes/:id/characters',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return CharactersScreen(universeId: id);
          },
        ),
        GoRoute(
          path: '/universes/:id/lore',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return LoreScreen(universeId: id);
          },
        ),
        GoRoute(
          path: '/universes/:id/scratchpad',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ScratchpadScreen(universeId: id);
          },
        ),
      ],
    ),
  ],
);
