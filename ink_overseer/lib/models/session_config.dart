import 'package:shared_preferences/shared_preferences.dart';

class SessionConfig {
  static const String keyScheduledStart = 'scheduled_start_epoch';
  static const String keyScheduledDuration = 'scheduled_duration_minutes';
  static const String keyCooldownUntil = 'cooldown_until_epoch';
  static const String keyLastDuration = 'last_session_duration_minutes';
  static const String keyTestModeEnabled = 'test_mode_enabled';

  static Future<void> saveSchedule({
    required DateTime startTime,
    required int durationMinutes,
    required bool isTestMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyScheduledStart, startTime.millisecondsSinceEpoch);
    await prefs.setInt(keyScheduledDuration, durationMinutes);
    await prefs.setBool(keyTestModeEnabled, isTestMode);
  }

  static Future<Map<String, dynamic>?> getSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final startEpoch = prefs.getInt(keyScheduledStart);
    final duration = prefs.getInt(keyScheduledDuration);
    final isTestMode = prefs.getBool(keyTestModeEnabled) ?? false;

    if (startEpoch == null || duration == null) return null;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startEpoch);
    return {
      'startTime': startTime,
      'durationMinutes': duration,
      'isTestMode': isTestMode,
    };
  }

  static Future<void> clearSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyScheduledStart);
    await prefs.remove(keyScheduledDuration);
  }

  static Future<void> triggerCooldown({
    required int sessionDurationMinutes,
    required bool isTestMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final Duration breakDuration;
    if (isTestMode) {
      breakDuration = const Duration(minutes: 1); // 1 minute break in test mode
    } else if (sessionDurationMinutes <= 60) {
      breakDuration = const Duration(minutes: 30); // 30 mins break
    } else {
      breakDuration = const Duration(minutes: 60); // 1 hour break
    }

    final cooldownExpiry = now.add(breakDuration);
    await prefs.setInt(keyCooldownUntil, cooldownExpiry.millisecondsSinceEpoch);
    await prefs.setInt(keyLastDuration, sessionDurationMinutes);
  }

  static Future<DateTime?> getCooldownExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt(keyCooldownUntil);
    if (epoch == null) return null;
    final expiry = DateTime.fromMillisecondsSinceEpoch(epoch);
    if (DateTime.now().isBefore(expiry)) {
      return expiry;
    }
    return null;
  }
}
