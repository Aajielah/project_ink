import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/providers.dart';
import '../../models/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final tempPath = await backupService.exportBackup();
      if (tempPath == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to generate backup.')),
        );
        return;
      }

      final tempFile = File(tempPath);
      final bytes = await tempFile.readAsBytes();

      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final defaultFileName = 'ProjectInk_Backup_$year-$month-$day.projectink';

      // 1. Try file picker save dialog (supported on Android using SAF when bytes are passed)
      String? outputPath;
      bool savedViaPicker = false;
      try {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Select export location',
          fileName: defaultFileName,
          bytes: bytes,
        );
        if (outputPath != null) {
          savedViaPicker = true;
        }
      } catch (e) {
        // saveFile is not supported or failed on this platform/SDK version
      }

      // 2. Fallback to Downloads directory if picker was cancelled or not supported
      if (outputPath == null) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          outputPath = '${downloadsDir.path}/$defaultFileName';
        }
      }

      // 3. Fallback to external storage directory on Android if Downloads is null
      if (outputPath == null && Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          outputPath = '${extDir.path}/$defaultFileName';
        }
      }

      // 4. If we didn't save via picker but found a fallback path, write the bytes manually
      if (outputPath != null) {
        if (!savedViaPicker) {
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(bytes);
        }

        // Clean up temp file
        try {
          await tempFile.delete();
        } catch (_) {}

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Backup exported successfully.')),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not determine a save location for the backup.')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error exporting backup: $e')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final backupService = ref.read(backupServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      
      // Validate backup file extension
      if (!path.toLowerCase().endsWith('.projectink')) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Invalid file format. Please select a .projectink file.')),
        );
        return;
      }
      
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
        SnackBar(content: Text('Error restoring backup: $e')),
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
                        'Project Ink v2.2',
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
