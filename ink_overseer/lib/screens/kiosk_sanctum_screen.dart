import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/kiosk_slot.dart';
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
  List<KioskSlot> _slots = KioskSlot.defaultSlots();
  bool _isTestMode = false;
  int _remainingSec = 0;
  int _currentCycleIndex = 0;
  int _aiSec = 0;
  int _whatsappSec = 0;
  int _utilitySec = 0;
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
    _loadSlots();
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

  Future<void> _loadSlots() async {
    final loaded = await SessionConfig.getSlots();
    if (mounted) {
      setState(() => _slots = loaded);
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
      _currentCycleIndex = state['currentCycleIndex'] as int? ?? 0;
      _aiSec = state['aiAllowanceRemainingSec'] as int? ?? 0;
      _whatsappSec = state['whatsappAllowanceRemainingSec'] as int? ?? 0;
      _utilitySec = state['utilityAllowanceRemainingSec'] as int? ?? 0;
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

  void _handleSlotTap(KioskSlot slot) {
    HapticFeedback.lightImpact();

    // Check if slot is permitted
    switch (slot.tier) {
      case 'sacred':
        _launch(slot.packageName);
        break;

      case 'ai':
        if (_aiSec > 0) {
          _launch(slot.packageName);
        } else {
          _showLockedSheet(
            title: 'AI Assistant Locked',
            message: 'Your 5-minute AI brainstorming pool has been exhausted for this 30-minute block.',
            resetsIn: 'Refreshes in next block cycle',
          );
        }
        break;

      case 'whatsapp':
        if (_currentCycleIndex == 0) {
          final minsLeftInPhase1 = _isTestMode ? (60 - (_remainingSec % 60)) : (1800 - (_remainingSec % 1800));
          _showLockedSheet(
            title: 'WhatsApp Locked (Phase 1)',
            message: 'WhatsApp is strictly locked during your first 30 minutes of deep focus to build flow momentum.',
            resetsIn: 'Unlocks automatically in ${_formatTime(minsLeftInPhase1)}',
          );
        } else if (_whatsappSec > 0) {
          _launch(slot.packageName);
        } else {
          _showLockedSheet(
            title: 'WhatsApp Leash Exhausted',
            message: 'Your WhatsApp allowance for this 30-minute block is finished.',
            resetsIn: 'Refreshes in next 30m cycle',
          );
        }
        break;

      case 'utility':
        if (_currentCycleIndex == 0) {
          _showLockedSheet(
            title: '${slot.displayName} Locked',
            message: 'Secondary apps are restricted during Phase 1 deep focus.',
            resetsIn: 'Unlocks in Phase 2 (min 31)',
          );
        } else if (_utilitySec > 0) {
          _launch(slot.packageName);
        } else {
          _showLockedSheet(
            title: '${slot.displayName} Pool Exhausted',
            message: 'Your 5-minute utility research pool has been used up for this block.',
            resetsIn: 'Refreshes in next block cycle',
          );
        }
        break;
    }
  }

  Future<void> _launch(String packageName) async {
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

  void _showLockedSheet({
    required String title,
    required String message,
    required String resetsIn,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: SanctumTheme.crimsonAlert, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SanctumTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: SanctumTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              resetsIn,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: SanctumTheme.amberWarning,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  OverseerChannel.openPureWriter();
                },
                icon: const Icon(Icons.edit_note, size: 22),
                label: const Text('Return to Pure Writer ✍️'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Kiosk lockdown: back button disabled
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
                        Icon(Icons.bolt, color: SanctumTheme.goldAccent, size: 18),
                        SizedBox(width: 4),
                        Text(
                          'ULTRA FOCUS SANCTUARY',
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
                        _currentCycleIndex == 0
                            ? 'Phase 1: Deep Writing'
                            : 'Phase 2: Cycle ${_currentCycleIndex + 1}',
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
                    children: const [
                      Icon(Icons.apps, size: 16, color: SanctumTheme.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'THE 6 SACRED SLOTS (LOCKED IN STONE)',
                        style: TextStyle(
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

                // 6 Slots Grid (2 columns x 3 rows)
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: _slots.length.clamp(0, 6),
                    itemBuilder: (ctx, i) => _buildSlotTile(_slots[i]),
                  ),
                ),

                // Bottom Emergency Lifeline Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SanctumTheme.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.phone_in_talk, color: SanctumTheme.emeraldReady, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phone calls, SMS, and Quran are unconditionally active.',
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

  Widget _buildSlotTile(KioskSlot slot) {
    // Determine badge and availability
    String badgeText = 'Active';
    Color badgeColor = SanctumTheme.emeraldReady;
    bool isAvailable = true;

    switch (slot.tier) {
      case 'sacred':
        badgeText = 'Unlimited';
        badgeColor = SanctumTheme.emeraldReady;
        isAvailable = true;
        break;

      case 'ai':
        if (_aiSec > 0) {
          badgeText = '${_formatTime(_aiSec)} left';
          badgeColor = SanctumTheme.goldAccent;
        } else {
          badgeText = 'Exhausted';
          badgeColor = SanctumTheme.crimsonAlert;
          isAvailable = false;
        }
        break;

      case 'whatsapp':
        if (_currentCycleIndex == 0) {
          badgeText = '🔒 Phase 1';
          badgeColor = SanctumTheme.amberWarning;
          isAvailable = false;
        } else if (_whatsappSec > 0) {
          badgeText = '${_formatTime(_whatsappSec)} left';
          badgeColor = SanctumTheme.emeraldReady;
        } else {
          badgeText = 'Exhausted';
          badgeColor = SanctumTheme.crimsonAlert;
          isAvailable = false;
        }
        break;

      case 'utility':
        if (_currentCycleIndex == 0) {
          badgeText = '🔒 Phase 1';
          badgeColor = SanctumTheme.amberWarning;
          isAvailable = false;
        } else if (_utilitySec > 0) {
          badgeText = '${_formatTime(_utilitySec)} left';
          badgeColor = SanctumTheme.goldAccent;
        } else {
          badgeText = 'Exhausted';
          badgeColor = SanctumTheme.crimsonAlert;
          isAvailable = false;
        }
        break;
    }

    return InkWell(
      onTap: () => _handleSlotTap(slot),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF12161E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? SanctumTheme.border : const Color(0xFF3B1E22),
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
                _buildSlotIcon(slot.iconType, isAvailable),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(38),
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
                  slot.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  slot.packageName,
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

  Widget _buildSlotIcon(String iconType, bool isAvailable) {
    IconData iconData = Icons.apps;
    Color color = SanctumTheme.goldAccent;

    switch (iconType) {
      case 'purewriter':
        iconData = Icons.edit_note;
        color = SanctumTheme.goldAccent;
        break;
      case 'phone':
        iconData = Icons.phone;
        color = SanctumTheme.emeraldReady;
        break;
      case 'messages':
        iconData = Icons.message;
        color = SanctumTheme.emeraldReady;
        break;
      case 'ai':
        iconData = Icons.psychology;
        color = Colors.lightBlueAccent;
        break;
      case 'whatsapp':
        iconData = Icons.chat;
        color = const Color(0xFF25D366);
        break;
      case 'quran':
        iconData = Icons.menu_book;
        color = SanctumTheme.goldAccent;
        break;
      case 'docs':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.language;
        color = SanctumTheme.textMuted;
    }

    if (!isAvailable) {
      color = SanctumTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: color, size: 22),
    );
  }
}
