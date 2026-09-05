import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicIconService {
  static const MethodChannel _channel = MethodChannel('com.projectink.project_ink/app_icon');

  static const String keyIconMode = 'app_icon_mode'; // 'dynamic', 'pen', 'bottle'
  static const String keyLastAppliedIcon = 'app_last_applied_icon'; // 'pen', 'bottle'

  /// Checks and applies the app icon according to the mode and current day.
  static Future<void> checkAndApplyDailyIcon() async {
    if (!Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(keyIconMode) ?? 'dynamic';

      String targetIcon;
      if (mode == 'pen') {
        targetIcon = 'pen';
      } else if (mode == 'bottle') {
        targetIcon = 'bottle';
      } else {
        // Dynamic: alternate every 24 hours / calendar day
        final now = DateTime.now();
        final daysSinceEpoch = now.difference(DateTime(2026, 1, 1)).inDays;
        targetIcon = (daysSinceEpoch % 2 == 0) ? 'pen' : 'bottle';
      }

      final lastApplied = prefs.getString(keyLastAppliedIcon);
      if (lastApplied != targetIcon) {
        await _channel.invokeMethod('setIcon', {'iconName': targetIcon});
        await prefs.setString(keyLastAppliedIcon, targetIcon);
      }
    } catch (_) {
      // Silently catch platform exceptions if running in test / non-Android environment
    }
  }

  /// Explicitly set the app icon mode from settings ('dynamic', 'pen', 'bottle')
  static Future<void> setIconMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyIconMode, mode);

    if (!Platform.isAndroid) return;

    try {
      String targetIcon;
      if (mode == 'pen') {
        targetIcon = 'pen';
      } else if (mode == 'bottle') {
        targetIcon = 'bottle';
      } else {
        final now = DateTime.now();
        final daysSinceEpoch = now.difference(DateTime(2026, 1, 1)).inDays;
        targetIcon = (daysSinceEpoch % 2 == 0) ? 'pen' : 'bottle';
      }

      await _channel.invokeMethod('setIcon', {'iconName': targetIcon});
      await prefs.setString(keyLastAppliedIcon, targetIcon);
    } catch (_) {}
  }

  /// Retrieves the current icon mode
  static Future<String> getIconMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyIconMode) ?? 'dynamic';
  }
}
