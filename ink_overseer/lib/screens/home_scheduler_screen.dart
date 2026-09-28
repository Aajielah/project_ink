import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/session_config.dart';
import '../services/notification_helper.dart';
import '../services/overseer_channel.dart';
import 'active_focus_screen.dart';

class HomeSchedulerScreen extends StatefulWidget {
  const HomeSchedulerScreen({super.key});

  @override
  State<HomeSchedulerScreen> createState() => _HomeSchedulerScreenState();
}

class _HomeSchedulerScreenState extends State<HomeSchedulerScreen> {
  DateTime? _cooldownExpiry;
  Timer? _cooldownTimer;

  // Scheduling State
  TimeOfDay _selectedTime = TimeOfDay.now();
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
          MaterialPageRoute(builder: (_) => const ActiveFocusScreen()),
        );
      }
      return;
    }

    // 2. Check cooldown
    final expiry = await SessionConfig.getCooldownExpiry();
    final schedule = await SessionConfig.getSchedule();

    if (mounted) {
      setState(() {
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
        MaterialPageRoute(builder: (_) => const ActiveFocusScreen()),
      );
    }
  }

  Future<void> _commitSchedule() async {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If selected time today has already passed, schedule for tomorrow
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    await SessionConfig.saveSchedule(
      startTime: scheduledDateTime,
      durationMinutes: _selectedDuration,
      isTestMode: _isTestMode,
    );

    // Schedule the T-30, T-10, T-5 notifications
    await NotificationHelper.scheduleRampUpNotifications(
      targetStartTime: scheduledDateTime,
      isTestMode: _isTestMode,
    );

    await _checkActiveOrCooldown();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session committed for ${DateFormat.jm().format(scheduledDateTime)} (${_selectedDuration}m). Prepare to write!',
          ),
          backgroundColor: SanctumTheme.emeraldReady,
        ),
      );
    }
  }

  Future<void> _startInstantSession() async {
    await SessionConfig.clearSchedule();
    final started = await OverseerChannel.startSession(
      durationMinutes: _isTestMode ? 5 : _selectedDuration,
      isTestMode: _isTestMode,
    );

    if (started && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActiveFocusScreen()),
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
                          setState(() => _selectedTime = picked);
                        }
                      },
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
                  await _checkActiveOrCooldown();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat.jm().format(scheduledStart),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: SanctumTheme.textPrimary,
            ),
          ),
          Text(
            'Duration: $duration minutes • Overseer will take over on time',
            style: const TextStyle(color: SanctumTheme.textSecondary, fontSize: 13),
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
}
