import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/providers.dart';
import '../../models/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final path = await backupService.exportBackup();
      if (path != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Exported'),
            content: Text('Your backup has been saved successfully to:\n\n$path'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to export backup.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['projectink'],
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Data'),
          content: const Text(
              'Importing this backup will overwrite all current writing projects, history logs, and settings. Do you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Overwrite & Restore'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final success = await backupService.importBackup(path);
      if (success) {
        // Invalidate all providers to reload the entire state from the new DB
        ref.invalidate(projectsProvider);
        ref.invalidate(settingsProvider);
        ref.invalidate(statisticsProvider);
        ref.invalidate(homeQuoteProvider(null));
        ref.invalidate(homeEncouragementProvider(null));

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backup Restored'),
            content: const Text('All your data has been restored successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to restore backup. Invalid or corrupt file.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Display/Theme section
              Text(
                'Appearance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette_outlined),
                          const SizedBox(width: 16),
                          Text('Theme Mode'),
                        ],
                      ),
                      DropdownButton<String>(
                        value: settings.theme,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('System')),
                          DropdownMenuItem(value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(settingsProvider.notifier).updateTheme(val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notifications and preferences
              Text(
                'Writing Preferences',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive daily writing reminders (Android only).'),
                      value: settings.notifications,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleNotifications(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.format_quote_outlined),
                      title: const Text('Daily Quotes'),
                      subtitle: const Text('Display writing motivation quotes on Dashboard.'),
                      value: settings.dailyQuotes,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleDailyQuotes(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_outlined),
                      title: const Text('Haptic Vibration'),
                      subtitle: const Text('Vibrate phone briefly on milestones and logs.'),
                      value: settings.vibration,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleVibration(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup section
              Text(
                'Data Backup & Safety',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: const Text('Export Backup'),
                      subtitle: const Text('Export all data to a .projectink file.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportBackup(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Import Backup'),
                      subtitle: const Text('Overwrite database from a backup file.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importBackup(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Project Ink v1.0.0',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'An offline-first writing productivity system designed to help writers consistently write and complete manuscripts.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
