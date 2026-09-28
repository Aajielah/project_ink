import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../services/overseer_channel.dart';
import 'home_scheduler_screen.dart';

class ActiveFocusScreen extends StatefulWidget {
  const ActiveFocusScreen({super.key});

  @override
  State<ActiveFocusScreen> createState() => _ActiveFocusScreenState();
}

class _ActiveFocusScreenState extends State<ActiveFocusScreen> {
  Timer? _timer;
  bool _isTestMode = false;
  int _remainingSec = 0;
  int _currentCycleIndex = 0;
  int _aiSec = 0;
  int _whatsappSec = 0;
  int _utilitySec = 0;
  int _totalSessionMinutes = 120;

  @override
  void initState() {
    super.initState();
    _refreshState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshState() async {
    final state = await OverseerChannel.getSessionState();
    if (!mounted) return;

    final isActive = state['isSessionActive'] as bool? ?? false;
    final remaining = state['remainingSec'] as int? ?? 0;

    if (!isActive || remaining <= 0) {
      _timer?.cancel();
      // Trigger cooldown when session finishes naturally
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Iron Cage: Cannot use back button to exit
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FOCUS SANCTUM ACTIVE'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isTestMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SanctumTheme.amberWarning.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SanctumTheme.amberWarning),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.science, color: SanctumTheme.amberWarning, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'TEST MODE: Fast-Forward Cycles Active',
                        style: TextStyle(
                          color: SanctumTheme.amberWarning,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Cycle Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SanctumTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SanctumTheme.border),
                ),
                child: Text(
                  _currentCycleIndex == 0
                      ? '🔒 Phase 1: First 30 Min Deep Lock'
                      : '🔓 Phase 2: Block Cycle ${_currentCycleIndex + 1}',
                  style: const TextStyle(
                    color: SanctumTheme.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Countdown Ring / Display
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SanctumTheme.surface,
                  border: Border.all(
                    color: SanctumTheme.goldAccent,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SanctumTheme.goldAccent.withAlpha(51),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SESSION REMAINING',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: SanctumTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSec),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: SanctumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✍️ Pure Focus Zone',
                      style: TextStyle(
                        fontSize: 13,
                        color: SanctumTheme.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Allowance Status Cards
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'APP ALLOWANCES (THIS 30M BLOCK)',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: SanctumTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildAllowanceCard(
                icon: Icons.psychology,
                title: 'AI Assistants (Gemini, Claude, GPT)',
                allowanceText: _aiSec > 0 ? _formatTime(_aiSec) : 'EXHAUSTED',
                isAvailable: _aiSec > 0,
                totalBudget: _isTestMode ? '30s' : '5m',
              ),

              _buildAllowanceCard(
                icon: Icons.chat,
                title: 'WhatsApp Leash',
                allowanceText: _currentCycleIndex == 0
                    ? 'LOCKED (Unlocks at min 31)'
                    : (_whatsappSec > 0 ? _formatTime(_whatsappSec) : 'EXHAUSTED'),
                isAvailable: _currentCycleIndex > 0 && _whatsappSec > 0,
                totalBudget: _isTestMode
                    ? '30s'
                    : (_totalSessionMinutes >= 120 ? '10m' : '5m'),
              ),

              _buildAllowanceCard(
                icon: Icons.language,
                title: 'Browsers & Novel Apps Pool',
                allowanceText: _currentCycleIndex == 0
                    ? 'LOCKED (Unlocks at min 31)'
                    : (_utilitySec > 0 ? _formatTime(_utilitySec) : 'EXHAUSTED'),
                isAvailable: _currentCycleIndex > 0 && _utilitySec > 0,
                totalBudget: _isTestMode ? '30s' : '5m',
              ),

              const SizedBox(height: 28),

              // Primary Hero Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    OverseerChannel.openPureWriter();
                  },
                  icon: const Icon(Icons.edit_note, size: 24),
                  label: const Text('Open Pure Writer Now'),
                ),
              ),

              const SizedBox(height: 16),

              // Unconditional Lifeline Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SanctumTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SanctumTheme.border),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined,
                        color: SanctumTheme.emeraldReady, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Calls, SMS, Quran, and Docs remain 100% accessible at all times.',
                        style: TextStyle(
                          fontSize: 12,
                          color: SanctumTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Test Mode Early Exit Button (only in test mode)
              if (_isTestMode) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    await OverseerChannel.stopSession(force: true);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeSchedulerScreen()),
                    );
                  },
                  icon: const Icon(Icons.stop_circle_outlined,
                      color: SanctumTheme.crimsonAlert),
                  label: const Text(
                    'End Test Session (Dev Only)',
                    style: TextStyle(color: SanctumTheme.crimsonAlert),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllowanceCard({
    required IconData icon,
    required String title,
    required String allowanceText,
    required bool isAvailable,
    required String totalBudget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvailable ? SanctumTheme.border : SanctumTheme.crimsonAlert.withAlpha(76),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isAvailable ? SanctumTheme.goldAccent : SanctumTheme.textMuted,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SanctumTheme.textPrimary,
                  ),
                ),
                Text(
                  'Pool allowance: $totalBudget',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SanctumTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            allowanceText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAvailable ? SanctumTheme.emeraldReady : SanctumTheme.crimsonAlert,
            ),
          ),
        ],
      ),
    );
  }
}
