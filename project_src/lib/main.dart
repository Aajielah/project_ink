import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'shared/providers.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(
    const ProviderScope(
      child: ProjectInkApp(),
    ),
  );
}

class ProjectInkApp extends ConsumerWidget {
  const ProjectInkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    // Initialize/seed the quotes in the background when the app starts
    ref.read(quoteRepositoryProvider).seedDatabaseQuotes();

    ThemeMode themeMode = ThemeMode.system;
    settingsAsync.whenData((settings) {
      if (settings.theme == 'light') {
        themeMode = ThemeMode.light;
      } else if (settings.theme == 'dark') {
        themeMode = ThemeMode.dark;
      } else {
        themeMode = ThemeMode.system;
      }
    });

    // Material 3 harmonious color schemes
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD0BCFF),
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'Project Ink',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );

  }
}
