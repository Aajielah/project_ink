import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers.dart';
import 'shared/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/dynamic_icon_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await DynamicIconService.checkAndApplyDailyIcon();
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
    final activePalette = ref.watch(themePaletteProvider);

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

    return MaterialApp.router(
      title: 'Project Ink',
      themeMode: themeMode,
      theme: AppTheme.getTheme(activePalette, isDark: false),
      darkTheme: AppTheme.getTheme(activePalette, isDark: true),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
