import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../shared/models/settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Settings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = ref.read(databaseServiceProvider);
    final settings = await db.getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    if (_settings == null) return;
    final currentTime = TimeOfDay(
      hour: _settings!.reminderTime.hour,
      minute: _settings!.reminderTime.minute,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      final now = DateTime.now();
      final newReminder = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      _settings!.reminderTime = newReminder;

      final db = ref.read(databaseServiceProvider);
      await db.saveSettings(_settings!);
      setState(() {});
    }
  }

  Future<void> _exportBackup() async {
    final passwordController = TextEditingController();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Encrypted Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a password to encrypt your backup with AES-256. You will need this password to restore your data.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Encryption Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate Backup'),
          ),
        ],
      ),
    );

    if (shouldExport == true && passwordController.text.isNotEmpty) {
      final db = ref.read(databaseServiceProvider);
      final encryptedPayload = await BackupService.exportEncryptedBackup(
        db,
        passwordController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Encrypted Backup Ready'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your database is secured with AES-256 encryption. Copy and save your backup payload:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    encryptedPayload.length > 100
                        ? '${encryptedPayload.substring(0, 100)}... (${encryptedPayload.length} chars)'
                        : encryptedPayload,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy to Clipboard'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: encryptedPayload));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Encrypted backup copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final payloadController = TextEditingController();
    final passwordController = TextEditingController();

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your AES-256 encrypted backup payload and enter the password to decrypt:'),
              const SizedBox(height: 12),
              TextField(
                controller: payloadController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Encrypted Payload',
                  hintText: 'Paste base64 payload here',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Decryption Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decrypt & Restore'),
          ),
        ],
      ),
    );

    if (shouldImport == true &&
        payloadController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      final db = ref.read(databaseServiceProvider);
      final success = await BackupService.importEncryptedBackup(
        db,
        payloadController.text.trim(),
        passwordController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Decryption failed. Check your password and payload.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final timeStr = _settings != null
        ? '${_settings!.reminderTime.hour.toString().padLeft(2, '0')}:${_settings!.reminderTime.minute.toString().padLeft(2, '0')}'
        : '20:00';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Notifications Section
          Text('Reminders & Tracking Day', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.alarm_rounded, color: Colors.blue),
                  title: const Text('Daily Reminder Time'),
                  subtitle: Text('Current: $timeStr'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _selectReminderTime,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.nightlight_round, color: Colors.amber),
                  title: Text('5:00 AM Daily Reset (Grace Period)'),
                  subtitle: Text(
                    'Tracking days run from 5:00 AM to 5:00 AM next day. This gives you a 5-hour grace window after midnight to complete and record yesterday\'s goals.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security & Encrypted Backup Section
          Text('Data Privacy & AES-256 Backup', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.green),
                  title: const Text('Export Encrypted Backup'),
                  subtitle: const Text('AES-256 password encrypted export'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.orange),
                  title: const Text('Import & Restore Database'),
                  subtitle: const Text('Decrypt and restore using your password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded, color: Colors.grey),
              title: Text('Daily Counter'),
              subtitle: Text('Version 1.0.0 • Offline-first commitment tracker'),
            ),
          ),
        ],
      ),
    );
  }
}
