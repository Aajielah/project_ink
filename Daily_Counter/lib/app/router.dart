import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_page.dart';
import '../features/projects/presentation/create_project_page.dart';
import '../features/projects/presentation/project_overview_page.dart';
import '../features/projects/presentation/edit_project_page.dart';
import '../features/history/presentation/project_history_page.dart';
import '../features/settings/presentation/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateProjectPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/overview/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ProjectOverviewPage(projectId: id);
      },
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return EditProjectPage(projectId: id);
      },
    ),
    GoRoute(
      path: '/history/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ProjectHistoryPage(projectId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('No route defined for ${state.uri}'),
    ),
  ),
);
