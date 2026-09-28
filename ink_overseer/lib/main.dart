import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/active_focus_screen.dart';
import 'screens/home_scheduler_screen.dart';
import 'screens/permission_guard_screen.dart';
import 'services/notification_helper.dart';
import 'services/overseer_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.initialize();
  runApp(const InkOverseerApp());
}

class InkOverseerApp extends StatelessWidget {
  const InkOverseerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Ink: Overseer',
      debugShowCheckedModeBanner: false,
      theme: SanctumTheme.darkTheme,
      home: const RootGateScreen(),
    );
  }
}

class RootGateScreen extends StatefulWidget {
  const RootGateScreen({super.key});

  @override
  State<RootGateScreen> createState() => _RootGateScreenState();
}

class _RootGateScreenState extends State<RootGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // 1. If an active session is running, lock into ActiveFocusScreen immediately
    final sessionState = await OverseerChannel.getSessionState();
    if (sessionState['isSessionActive'] == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ActiveFocusScreen()),
        );
      }
      return;
    }

    // 2. Check permissions
    final perms = await OverseerChannel.checkPermissions();
    final allGranted = (perms['overlayEnabled'] ?? false) &&
        (perms['accessibilityEnabled'] ?? false) &&
        (perms['deviceAdminEnabled'] ?? false) &&
        (perms['usageStatsEnabled'] ?? false);

    if (mounted) {
      if (allGranted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeSchedulerScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PermissionGuardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SanctumTheme.background,
      body: Center(
        child: CircularProgressIndicator(
          color: SanctumTheme.goldAccent,
        ),
      ),
    );
  }
}
