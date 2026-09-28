import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/overseer_channel.dart';
import 'home_scheduler_screen.dart';

class PermissionGuardScreen extends StatefulWidget {
  const PermissionGuardScreen({super.key});

  @override
  State<PermissionGuardScreen> createState() => _PermissionGuardScreenState();
}

class _PermissionGuardScreenState extends State<PermissionGuardScreen>
    with WidgetsBindingObserver {
  bool _overlay = false;
  bool _accessibility = false;
  bool _deviceAdmin = false;
  bool _usageStats = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final status = await OverseerChannel.checkPermissions();
    if (!mounted) return;

    setState(() {
      _overlay = status['overlayEnabled'] ?? false;
      _accessibility = status['accessibilityEnabled'] ?? false;
      _deviceAdmin = status['deviceAdminEnabled'] ?? false;
      _usageStats = status['usageStatsEnabled'] ?? false;
      _isLoading = false;
    });

    if (_overlay && _accessibility && _deviceAdmin && _usageStats) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeSchedulerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOCUS SANCTUM SETUP'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SanctumTheme.goldAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Iron Cage Activation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: SanctumTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To block distracting apps and enforce your writing schedules without bypass, Overseer requires 4 system permissions.',
                    style: TextStyle(
                      fontSize: 14,
                      color: SanctumTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPermissionTile(
                    title: 'Display Over Other Apps',
                    desc: 'Draws the lock screen overlay when unauthorized apps are opened.',
                    isGranted: _overlay,
                    onGrant: OverseerChannel.requestOverlayPermission,
                  ),
                  _buildPermissionTile(
                    title: 'Accessibility Service',
                    desc: 'Detects within 100ms when you leave Pure Writer for distraction feeds.',
                    isGranted: _accessibility,
                    onGrant: OverseerChannel.requestAccessibilityPermission,
                  ),
                  _buildPermissionTile(
                    title: 'Device Administrator',
                    desc: 'Prevents compulsive uninstallation while a session is locked.',
                    isGranted: _deviceAdmin,
                    onGrant: OverseerChannel.requestDeviceAdminPermission,
                  ),
                  _buildPermissionTile(
                    title: 'Usage Access',
                    desc: 'Accurately tracks active minutes spent in WhatsApp and AI apps.',
                    isGranted: _usageStats,
                    onGrant: OverseerChannel.requestUsageStatsPermission,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // In case user wants to test on emulator or bypass for now
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeSchedulerScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SanctumTheme.surfaceElevated,
                        foregroundColor: SanctumTheme.goldLight,
                      ),
                      child: const Text('Continue to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? SanctumTheme.emeraldReady : SanctumTheme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isGranted
                ? SanctumTheme.emeraldReady
                : SanctumTheme.textMuted,
            size: 26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SanctumTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SanctumTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onGrant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SanctumTheme.goldAccent,
                      foregroundColor: SanctumTheme.background,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
