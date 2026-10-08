import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../services/notification_helper.dart';
import '../services/overseer_channel.dart';
import 'kiosk_sanctum_screen.dart';
import 'tier_setup_screen.dart';
import '../models/tier_app.dart';

class HomeSchedulerScreen extends StatefulWidget {
  const HomeSchedulerScreen({super.key});

  @override
  State<HomeSchedulerScreen> createState() => _HomeSchedulerScreenState();
}

class _HomeSchedulerScreenState extends State<HomeSchedulerScreen> {
  DateTime? _cooldownExpiry;
  Timer? _cooldownTimer;
  int _tierAppsCount = 0;

  // Scheduling State
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _customTargetDateTime;
  int _selectedDuration = 120; // 2 hours default
  bool _isTestMode = false;
  Map<String, dynamic>? _existingSchedule;

  final List<String> _quotes = [
    "\"Start writing, no matter what. The water does not flow until the faucet is turned on.\" — Louis L'Amour",
    "\"You can't edit a blank page. Go make words.\" — Jodi Picoult",
    "\"Amateurs sit and wait for inspiration, the rest of us just get up and go to work.\" — Stephen King",
    "\"Writing is a muscle. Train it daily or watch it atrophy.\" — Focus Sanctum",
    "\"WhatsApp and reels will exist tomorrow. Your writing hours will not.\" — Project Ink",
  ];
  late String _todaysQuote;

  @override
  void initState() {
    super.initState();
    _todaysQuote = (_quotes..shuffle()).first;
    _checkActiveOrCooldown();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkActiveOrCooldown() async {
    // 1. Check if session is already active in background
    final state = await OverseerChannel.getSessionState();
    if (state['isSessionActive'] == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KioskSanctumScreen()),
        );
      }
      return;
    }

    // 2. Check cooldown & tier apps
    final expiry = await SessionConfig.getCooldownExpiry();
    final schedule = await SessionConfig.getSchedule();
    final tierApps = await SessionConfig.getTierApps();

    if (mounted) {
      setState(() {
        _tierAppsCount = tierApps.length;
        _cooldownExpiry = expiry;
        _existingSchedule = schedule;
        if (schedule != null) {
          _selectedDuration = schedule['durationMinutes'] as int;
          _isTestMode = schedule['isTestMode'] as bool;
        }
      });
    }
  }

  void _tick() {
    if (_cooldownExpiry != null) {
      if (DateTime.now().isAfter(_cooldownExpiry!)) {
        setState(() => _cooldownExpiry = null);
      } else {
        setState(() {}); // refresh cooldown countdown
      }
    }

    // Check if scheduled time has arrived!
    if (_existingSchedule != null) {
      final scheduledStart = _existingSchedule!['startTime'] as DateTime;
      if (DateTime.now().isAfter(scheduledStart)) {
        _launchScheduledSession();
      }
    }
  }

  Future<void> _launchScheduledSession() async {
    final duration = _existingSchedule!['durationMinutes'] as int;
    final isTest = _existingSchedule!['isTestMode'] as bool;
    await SessionConfig.clearSchedule();

    final started = await OverseerChannel.startSession(
      durationMinutes: duration,
      isTestMode: isTest,
    );

    if (started && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KioskSanctumScreen()),
      );
    }
  }

  Future<void> _commitSchedule() async {
    final tierApps = await SessionConfig.getTierApps();
    final hasTier1 = tierApps.any((t) => t.tier == AppTier.tier1Writing);
    if (!hasTier1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please assign at least 1 writing app (Pure Writer) to Tier 1 first!'),
            backgroundColor: SanctumTheme.amberWarning,
          ),
        );
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TierSetupScreen()),
        );
        if (updated == true) {
          final refreshed = await SessionConfig.getTierApps();
          setState(() => _tierAppsCount = refreshed.length);
        }
      }
      return;
    }

    final now = DateTime.now();
    DateTime scheduledDateTime;

    if (_customTargetDateTime != null && _customTargetDateTime!.isAfter(now)) {
      scheduledDateTime = _customTargetDateTime!;
    } else {
      scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // If selected time today has already passed:
      if (scheduledDateTime.isBefore(now)) {
        if (now.difference(scheduledDateTime).inMinutes <= 10) {
          // User picked the current minute or just missed the clock tick: start in 1 minute today!
          scheduledDateTime = now.add(const Duration(minutes: 1));
        } else {
          // User picked an hour earlier today, schedule for tomorrow
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
      }
    }

    // Enforce minimum 30-second buffer for scheduled sessions
    if (scheduledDateTime.difference(now).inSeconds < 30) {
      scheduledDateTime = now.add(const Duration(seconds: 45));
    }

    await SessionConfig.saveSchedule(
      startTime: scheduledDateTime,
      durationMinutes: _selectedDuration,
      isTestMode: _isTestMode,
    );

    // Schedule the T-30, T-10, T-5 notifications and T=0 alarm takeover
    await NotificationHelper.scheduleRampUpNotifications(
      targetStartTime: scheduledDateTime,
      isTestMode: _isTestMode,
    );

    // Schedule exact hardware-backed Android AlarmManager wakeup at T=0
    await OverseerChannel.scheduleSessionAlarm(
      scheduledDateTime.millisecondsSinceEpoch,
    );

    await _checkActiveOrCooldown();

    final isToday = scheduledDateTime.day == now.day && scheduledDateTime.month == now.month;
    final dayLabel = isToday ? 'Today' : 'Tomorrow';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session committed for $dayLabel at ${DateFormat.jm().format(scheduledDateTime)} (${_selectedDuration}m). Prepare to write!',
          ),
          backgroundColor: SanctumTheme.emeraldReady,
        ),
      );
    }
  }

  Future<void> _startInstantSession() async {
    final tierApps = await SessionConfig.getTierApps();
    final hasTier1 = tierApps.any((t) => t.tier == AppTier.tier1Writing);
    if (!hasTier1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please assign at least 1 writing app (Pure Writer) to Tier 1 first!'),
            backgroundColor: SanctumTheme.amberWarning,
          ),
        );
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const TierSetupScreen()),
        );
        if (updated == true) {
          final refreshed = await SessionConfig.getTierApps();
          setState(() => _tierAppsCount = refreshed.length);
        }
      }
      return;
    }

    await SessionConfig.clearSchedule();
    final started = await OverseerChannel.startSession(
      durationMinutes: _isTestMode ? 5 : _selectedDuration,
      isTestMode: _isTestMode,
    );

    if (started && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KioskSanctumScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCooldownActive = _cooldownExpiry != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FOCUS SANCTUM'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Motivation Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SanctumTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SanctumTheme.border),
              ),
              child: Row(
                children: [
                  const Text('🖋️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _todaysQuote,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: SanctumTheme.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mandatory Cooldown Banner (if resting)
            if (isCooldownActive) ...[
              _buildCooldownBanner(),
              const SizedBox(height: 24),
            ],

            // Active Upcoming Schedule Card
            if (_existingSchedule != null && !isCooldownActive) ...[
              _buildUpcomingScheduleCard(),
              const SizedBox(height: 24),
            ],

            // Sacred 6 Slots Configuration Card
            _buildSlotsConfigCard(),
            const SizedBox(height: 24),

            // Schedule Setup Form (disabled during cooldown)
            Opacity(
              opacity: isCooldownActive ? 0.4 : 1.0,
              child: IgnorePointer(
                ignoring: isCooldownActive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Today\'s Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SanctumTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Strictly one active session allowed at a time. The app will notify you before takeover.',
                      style: TextStyle(
                        fontSize: 13,
                        color: SanctumTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Test Mode Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isTestMode
                            ? SanctumTheme.amberWarning.withAlpha(38)
                            : SanctumTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isTestMode
                              ? SanctumTheme.amberWarning
                              : SanctumTheme.border,
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '🧪 Test Mode (5–10 Min Quick Cycles)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: SanctumTheme.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Fast-forwards cycles to 1 minute so you can test WhatsApp locks, AI timers, and overlays right now.',
                          style: TextStyle(
                            fontSize: 12,
                            color: SanctumTheme.textSecondary,
                          ),
                        ),
                        value: _isTestMode,
                        activeThumbColor: SanctumTheme.amberWarning,
                        onChanged: (val) {
                          setState(() {
                            _isTestMode = val;
                            _selectedDuration = val ? 5 : 120;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Time Selector
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: SanctumTheme.border),
                      ),
                      tileColor: SanctumTheme.surface,
                      leading: const Icon(Icons.access_time, color: SanctumTheme.goldAccent),
                      title: const Text(
                        'Start Time',
                        style: TextStyle(color: SanctumTheme.textSecondary, fontSize: 13),
                      ),
                      subtitle: Text(
                        _getTargetSummary(),
                        style: const TextStyle(
                          color: SanctumTheme.goldAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          color: SanctumTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                            _customTargetDateTime = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick Prep Presets
                    const Text(
                      'QUICK PREP PRESETS (STARTS TODAY)',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: SanctumTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickPrepChip(1, '+1 Min (Quick Test)'),
                        _buildQuickPrepChip(5, '+5 Mins (Fast Prep)'),
                        _buildQuickPrepChip(10, '+10 Mins (Standard)'),
                        _buildQuickPrepChip(15, '+15 Mins'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Duration Selector
                    Text(
                      _isTestMode
                          ? 'TEST DURATION (MINUTES)'
                          : 'SESSION DURATION (1H MIN - 3H MAX)',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: SanctumTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _isTestMode
                        ? Row(
                            children: [
                              _buildDurationChip(5, '5 Minutes (Test)'),
                              const SizedBox(width: 12),
                              _buildDurationChip(10, '10 Minutes (Test)'),
                            ],
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildDurationChip(60, '1 Hour'),
                              _buildDurationChip(90, '1.5 Hours'),
                              _buildDurationChip(120, '2 Hours (Recommended)'),
                              _buildDurationChip(180, '3 Hours (Max)'),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Ramp-up Timeline Preview
                    _buildRampUpPreview(),
                    const SizedBox(height: 28),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _commitSchedule,
                        icon: const Icon(Icons.alarm_on, size: 22),
                        label: const Text('Commit Writing Schedule'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _startInstantSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SanctumTheme.goldLight,
                          side: const BorderSide(color: SanctumTheme.goldAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.flash_on, size: 20),
                        label: Text(_isTestMode
                            ? 'Start Instant 5-Min Test Lock 🚀'
                            : 'Start Session Immediately 🚀'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = _selectedDuration == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: SanctumTheme.goldAccent,
      backgroundColor: SanctumTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? SanctumTheme.background : SanctumTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? SanctumTheme.goldAccent : SanctumTheme.border,
        ),
      ),
      onSelected: (_) {
        setState(() => _selectedDuration = minutes);
      },
    );
  }

  Widget _buildQuickPrepChip(int minutes, String label) {
    return ActionChip(
      avatar: const Icon(Icons.bolt, size: 16, color: SanctumTheme.goldAccent),
      label: Text(label),
      backgroundColor: SanctumTheme.surface,
      labelStyle: const TextStyle(
        color: SanctumTheme.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: SanctumTheme.border),
      ),
      onPressed: () {
        final target = DateTime.now().add(Duration(minutes: minutes));
        setState(() {
          _customTargetDateTime = target;
          _selectedTime = TimeOfDay.fromDateTime(target);
        });
      },
    );
  }

  String _getTargetSummary() {
    final now = DateTime.now();
    DateTime target;
    if (_customTargetDateTime != null && _customTargetDateTime!.isAfter(now)) {
      target = _customTargetDateTime!;
    } else {
      target = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      if (target.isBefore(now)) {
        if (now.difference(target).inMinutes <= 10) {
          target = now.add(const Duration(minutes: 1));
        } else {
          target = target.add(const Duration(days: 1));
        }
      }
    }
    final isToday = target.day == now.day && target.month == now.month && target.year == now.year;
    final prefix = isToday ? 'Today' : 'Tomorrow';
    final diff = target.difference(now);
    final inMins = diff.inMinutes;
    final inSecs = diff.inSeconds % 60;
    if (inMins < 60) {
      return '$prefix at ${DateFormat.jm().format(target)} (in ${inMins}m ${inSecs}s)';
    } else {
      final hours = inMins ~/ 60;
      final remMins = inMins % 60;
      return '$prefix at ${DateFormat.jm().format(target)} (in ${hours}h ${remMins}m)';
    }
  }

  Widget _buildCooldownBanner() {
    final diff = _cooldownExpiry!.difference(DateTime.now());
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SanctumTheme.amberWarning.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SanctumTheme.amberWarning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bedtime, color: SanctumTheme.amberWarning),
              SizedBox(width: 8),
              Text(
                'Mandatory Break / Cooldown Active',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: SanctumTheme.amberWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your previous writing session was completed. Mind rest is mandatory before your next block. Next session available in:',
            style: TextStyle(color: SanctumTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: SanctumTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingScheduleCard() {
    final scheduledStart = _existingSchedule!['startTime'] as DateTime;
    final duration = _existingSchedule!['durationMinutes'] as int;

    final now = DateTime.now();
    final diff = scheduledStart.difference(now);
    final remainingSec = diff.inSeconds > 0 ? diff.inSeconds : 0;
    final h = remainingSec ~/ 3600;
    final m = (remainingSec % 3600) ~/ 60;
    final s = remainingSec % 60;
    final countdownStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final isToday = scheduledStart.day == now.day && scheduledStart.month == now.month && scheduledStart.year == now.year;
    final dayLabel = isToday ? 'Today' : 'Tomorrow';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SanctumTheme.goldAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING SESSION QUEUED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: SanctumTheme.goldAccent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: SanctumTheme.crimsonAlert, size: 20),
                onPressed: () async {
                  await SessionConfig.clearSchedule();
                  await NotificationHelper.cancelAllNotifications();
                  await OverseerChannel.cancelSessionAlarm();
                  await _checkActiveOrCooldown();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$dayLabel at ${DateFormat.jm().format(scheduledStart)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: SanctumTheme.textPrimary,
            ),
          ),
          Text(
            'Duration: $duration minutes • Focus Sanctum will take over on time',
            style: const TextStyle(color: SanctumTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: SanctumTheme.goldAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SanctumTheme.goldAccent.withAlpha(120)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: SanctumTheme.goldAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Takeover in: $countdownStr',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: SanctumTheme.goldAccent,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Prep Countdown',
                  style: TextStyle(
                    fontSize: 11,
                    color: SanctumTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRampUpPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SanctumTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RAMP-UP NOTIFICATION SEQUENCE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: SanctumTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelineStep(
            _isTestMode ? 'T - 1 min' : 'T - 30 min',
            'First heads-up chime: Prepare your mind to write.',
          ),
          if (!_isTestMode) ...[
            _buildTimelineStep(
              'T - 10 min',
              'Second warning: Wrap up tabs, messages, and calls.',
            ),
            _buildTimelineStep(
              'T - 5 min',
              'Urgent chime: Final call to enter Pure Writer.',
            ),
          ],
          _buildTimelineStep(
            'T = 0',
            'Full Phone Takeover: Lockdown engages into Pure Writer.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String time, String desc, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time.padRight(12),
            style: const TextStyle(
              color: SanctumTheme.goldAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: SanctumTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SanctumTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SanctumTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SanctumTheme.goldAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.layers_outlined, color: SanctumTheme.goldAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '4-Tier Focus Environment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: SanctumTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tierAppsCount > 0
                      ? '$_tierAppsCount / 8 apps configured across 4 tiers'
                      : 'Configure Pure Writer, WhatsApp leash, AI & secondary tools',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SanctumTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const TierSetupScreen()),
              );
              if (updated == true) {
                final refreshed = await SessionConfig.getTierApps();
                setState(() => _tierAppsCount = refreshed.length);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: SanctumTheme.goldAccent,
              side: const BorderSide(color: SanctumTheme.goldAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Setup Tiers', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
