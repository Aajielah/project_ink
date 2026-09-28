import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../models/tier_app.dart';
import '../services/overseer_channel.dart';
import 'home_scheduler_screen.dart';

class KioskSanctumScreen extends StatefulWidget {
  const KioskSanctumScreen({super.key});

  @override
  State<KioskSanctumScreen> createState() => _KioskSanctumScreenState();
}

class _KioskSanctumScreenState extends State<KioskSanctumScreen> {
  Timer? _ticker;
  List<TierApp> _tierApps = [];
  bool _isTestMode = false;
  int _remainingSec = 0;
  int _totalSessionMinutes = 120;
  int _currentCycleIndex = 0;
  int _aiAllowanceRemainingSec = 300;
  int _whatsappAllowanceRemainingSec = 0;
  int _utilityAllowanceRemainingSec = 0;

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
    _loadTierApps();
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

  Future<void> _loadTierApps() async {
    final loaded = await SessionConfig.getTierApps();
    if (mounted) {
      if (loaded.isNotEmpty) {
        setState(() => _tierApps = loaded);
      } else {
        // Backward-compatibility fallback
        final legacy = await SessionConfig.getAllowedApps();
        setState(() {
          _tierApps = legacy
              .map((a) => TierApp(
                    packageName: a['packageName'] ?? '',
                    displayName: a['displayName'] ?? '',
                    tier: AppTier.tier1Writing,
                  ))
              .toList();
        });
      }
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
      _currentCycleIndex = state['currentCycleIndex'] as int? ?? 0;
      _aiAllowanceRemainingSec = state['aiAllowanceRemainingSec'] as int? ?? 0;
      _whatsappAllowanceRemainingSec = state['whatsappAllowanceRemainingSec'] as int? ?? 0;
      _utilityAllowanceRemainingSec = state['utilityAllowanceRemainingSec'] as int? ?? 0;
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

  Future<void> _handleAppTap(TierApp app) async {
    final isPhase1 = _currentCycleIndex == 0;

    // Check accessibility rules before attempting launch
    if (app.tier == AppTier.tier2WhatsApp) {
      if (isPhase1) {
        _showLockedNotice('🔒 WhatsApp is locked in Phase 1 (first ${_isTestMode ? "1 min" : "30 mins"}). Unlocks in Phase 2!');
        return;
      }
      if (_whatsappAllowanceRemainingSec <= 0) {
        _showLockedNotice('⏳ WhatsApp allowance depleted for this 30-minute block.');
        return;
      }
    } else if (app.tier == AppTier.tier3Ai) {
      if (_aiAllowanceRemainingSec <= 0) {
        _showLockedNotice('⏳ AI Brainstorming allowance depleted for this block.');
        return;
      }
    } else if (app.tier == AppTier.tier4Secondary) {
      if (isPhase1) {
        _showLockedNotice('🔒 Secondary tools (Docs, Webnovel, etc.) unlock in Phase 2 to prevent distraction.');
        return;
      }
    }

    HapticFeedback.lightImpact();
    final ok = await OverseerChannel.launchPackage(app.packageName);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open ${app.displayName}. Make sure it is installed.'),
          backgroundColor: SanctumTheme.crimsonAlert,
        ),
      );
    }
  }

  void _showLockedNotice(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SanctumTheme.crimsonAlert,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhase1 = _currentCycleIndex == 0;

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
                const SizedBox(height: 16),

                // Phase Indicator Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPhase1
                        ? SanctumTheme.amberWarning.withAlpha(25)
                        : SanctumTheme.emeraldReady.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPhase1
                          ? SanctumTheme.amberWarning.withAlpha(120)
                          : SanctumTheme.emeraldReady.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPhase1 ? Icons.lock_clock : Icons.check_circle_outline,
                        color: isPhase1 ? SanctumTheme.amberWarning : SanctumTheme.emeraldReady,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPhase1
                              ? 'Phase 1: Monk Stage (${_isTestMode ? "1m" : "0–30m"}) • Pure Writer Only'
                              : 'Phase 2: Execution & Tools • Secondary Apps & Social Leash Active',
                          style: TextStyle(
                            color: isPhase1 ? SanctumTheme.amberWarning : SanctumTheme.emeraldReady,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Permitted Apps Subtitle
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.apps, size: 16, color: SanctumTheme.goldAccent),
                      const SizedBox(width: 6),
                      Text(
                        'PERMITTED APPS (${_tierApps.length} CONFIGURED)',
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
                const SizedBox(height: 10),

                // 4-Tier Allowed Apps Grid
                Expanded(
                  child: _tierApps.isEmpty
                      ? const Center(
                          child: Text(
                            'No apps configured.',
                            style: TextStyle(color: SanctumTheme.textMuted),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: _tierApps.length,
                          itemBuilder: (ctx, i) => _buildTierAppTile(_tierApps[i], isPhase1),
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
                    children: [
                      const Icon(Icons.lock, color: SanctumTheme.goldAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPhase1
                              ? 'Phase 1: WhatsApp and Secondary Tools are locked.'
                              : 'Phase 2: Secondary tools unlocked. WhatsApp metered.',
                          style: const TextStyle(fontSize: 11, color: SanctumTheme.textSecondary),
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

  Widget _buildTierAppTile(TierApp app, bool isPhase1) {
    String badgeText;
    Color badgeColor;
    bool isAccessible;
    String tierLabel;

    switch (app.tier) {
      case AppTier.tier1Writing:
        tierLabel = 'Tier 1';
        badgeText = 'Unlimited';
        badgeColor = SanctumTheme.emeraldReady;
        isAccessible = true;
        break;

      case AppTier.tier2WhatsApp:
        tierLabel = 'Tier 2';
        if (isPhase1) {
          badgeText = 'Phase 1 Lock';
          badgeColor = SanctumTheme.amberWarning;
          isAccessible = false;
        } else if (_whatsappAllowanceRemainingSec > 0) {
          badgeText = '💬 ${_formatTime(_whatsappAllowanceRemainingSec)}';
          badgeColor = SanctumTheme.goldAccent;
          isAccessible = true;
        } else {
          badgeText = 'Depleted';
          badgeColor = SanctumTheme.crimsonAlert;
          isAccessible = false;
        }
        break;

      case AppTier.tier3Ai:
        tierLabel = 'Tier 3';
        if (_aiAllowanceRemainingSec > 0) {
          badgeText = '🤖 ${_formatTime(_aiAllowanceRemainingSec)}';
          badgeColor = Colors.lightBlueAccent;
          isAccessible = true;
        } else {
          badgeText = 'Depleted';
          badgeColor = SanctumTheme.crimsonAlert;
          isAccessible = false;
        }
        break;

      case AppTier.tier4Secondary:
        tierLabel = 'Tier 4';
        if (isPhase1) {
          badgeText = 'Phase 1 Lock';
          badgeColor = Colors.purpleAccent;
          isAccessible = false;
        } else {
          badgeText = 'Unlocked';
          badgeColor = Colors.purpleAccent;
          isAccessible = true;
        }
        break;
    }

    return InkWell(
      onTap: () => _handleAppTap(app),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAccessible ? const Color(0xFF12161E) : const Color(0xFF0F1218),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAccessible ? SanctumTheme.border : Colors.white10,
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
                  radius: 14,
                  backgroundColor: badgeColor.withAlpha(35),
                  child: Text(
                    tierLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withAlpha(128)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isAccessible ? Colors.white : SanctumTheme.textMuted,
                  ),
                ),
                Text(
                  app.packageName,
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
