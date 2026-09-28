import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../services/overseer_channel.dart';
import 'home_scheduler_screen.dart';

class KioskSanctumScreen extends StatefulWidget {
  const KioskSanctumScreen({super.key});

  @override
  State<KioskSanctumScreen> createState() => _KioskSanctumScreenState();
}

class _KioskSanctumScreenState extends State<KioskSanctumScreen> {
  Timer? _ticker;
  List<Map<String, String>> _allowedApps = [];
  bool _isTestMode = false;
  int _remainingSec = 0;
  int _totalSessionMinutes = 120;

  final List<String> _quotes = [
    "\"Start writing, no matter what. The water does not flow until the faucet is turned on.\" — Louis L'Amour",
    "\"You can't edit a blank page. Go make words.\" — Jodi Picoult",
    "\"Amateurs sit and wait for inspiration, the rest of us just get up and go to work.\" — Stephen King",
    "\"WhatsApp and reels will exist tomorrow. Your writing hours will not.\" — Project Ink",
    "\"The scariest moment is always just before you start.\" — Stephen King",
  ];
  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = (_quotes..shuffle()).first;
    _loadAllowedApps();
    _refreshState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _refreshState());

    // Enter immersive sticky mode for ultra battery saver feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadAllowedApps() async {
    final loaded = await SessionConfig.getAllowedApps();
    if (mounted) {
      setState(() => _allowedApps = loaded);
    }
  }

  Future<void> _refreshState() async {
    final state = await OverseerChannel.getSessionState();
    if (!mounted) return;

    final isActive = state['isSessionActive'] as bool? ?? false;
    final remaining = state['remainingSec'] as int? ?? 0;

    if (!isActive || remaining <= 0) {
      _ticker?.cancel();
      await SessionConfig.triggerCooldown(
        sessionDurationMinutes: _totalSessionMinutes,
        isTestMode: _isTestMode,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeSchedulerScreen()),
      );
      return;
    }

    setState(() {
      _isTestMode = state['isTestMode'] as bool? ?? false;
      _remainingSec = remaining;
      _totalSessionMinutes = state['totalSessionMinutes'] as int? ?? 120;
    });
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _launch(String packageName) async {
    HapticFeedback.lightImpact();
    final ok = await OverseerChannel.launchPackage(packageName);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $packageName. Make sure it is installed.'),
          backgroundColor: SanctumTheme.crimsonAlert,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Strict Mode: back button disabled
      child: Scaffold(
        backgroundColor: Colors.black, // Pitch Black Ultra Battery Saver
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Battery Saver Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.shield, color: SanctumTheme.goldAccent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'STRICT FOCUS SANCTUM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: SanctumTheme.goldAccent,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SanctumTheme.border),
                      ),
                      child: Text(
                        _isTestMode ? 'Test Mode' : 'Strict Mode Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SanctumTheme.emeraldReady,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Central Countdown Clock
                Text(
                  _formatTime(_remainingSec),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentQuote,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: SanctumTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                // Subtitle
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: SanctumTheme.emeraldReady),
                      const SizedBox(width: 6),
                      Text(
                        'PERMITTED APPS (${_allowedApps.length} CHOSEN)',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: SanctumTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Allowed Apps Grid
                Expanded(
                  child: _allowedApps.isEmpty
                      ? const Center(
                          child: Text(
                            'No apps selected.',
                            style: TextStyle(color: SanctumTheme.textMuted),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: _allowedApps.length,
                          itemBuilder: (ctx, i) => _buildAppTile(_allowedApps[i]),
                        ),
                ),

                // Bottom Lockdown Notice Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SanctumTheme.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock, color: SanctumTheme.goldAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your home screen and all other apps are blocked until timer ends.',
                          style: TextStyle(fontSize: 11, color: SanctumTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isTestMode) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      await OverseerChannel.stopSession(force: true);
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeSchedulerScreen()),
                      );
                    },
                    icon: const Icon(Icons.stop_circle_outlined, color: SanctumTheme.crimsonAlert, size: 18),
                    label: const Text(
                      'End Test Session (Dev Only)',
                      style: TextStyle(color: SanctumTheme.crimsonAlert, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppTile(Map<String, String> app) {
    final pkg = app['packageName'] ?? '';
    final name = app['displayName'] ?? pkg;

    return InkWell(
      onTap: () => _launch(pkg),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF12161E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SanctumTheme.border,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: SanctumTheme.goldAccent.withAlpha(35),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: SanctumTheme.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SanctumTheme.emeraldReady.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SanctumTheme.emeraldReady.withAlpha(128)),
                  ),
                  child: const Text(
                    'Allowed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SanctumTheme.emeraldReady,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  pkg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: SanctumTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
