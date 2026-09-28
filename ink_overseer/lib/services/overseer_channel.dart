import 'package:flutter/services.dart';

class OverseerChannel {
  static const MethodChannel _channel = MethodChannel('com.projectink.overseer/channel');

  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPermissionsStatus');
      if (res != null) {
        return {
          'overlayEnabled': res['overlayEnabled'] as bool? ?? false,
          'accessibilityEnabled': res['accessibilityEnabled'] as bool? ?? false,
          'deviceAdminEnabled': res['deviceAdminEnabled'] as bool? ?? false,
          'usageStatsEnabled': res['usageStatsEnabled'] as bool? ?? false,
        };
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error checking permissions: $e');
    }
    return {
      'overlayEnabled': false,
      'accessibilityEnabled': false,
      'deviceAdminEnabled': false,
      'usageStatsEnabled': false,
    };
  }

  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<void> requestAccessibilityPermission() async {
    await _channel.invokeMethod('requestAccessibilityPermission');
  }

  static Future<void> requestDeviceAdminPermission() async {
    await _channel.invokeMethod('requestDeviceAdminPermission');
  }

  static Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  static Future<bool> startSession({
    required int durationMinutes,
    required bool isTestMode,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('startSession', {
        'durationMinutes': durationMinutes,
        'isTestMode': isTestMode,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error starting session: $e');
      return false;
    }
  }

  static Future<bool> stopSession({bool force = false}) async {
    try {
      final res = await _channel.invokeMethod<bool>('stopSession', {
        'force': force,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error stopping session: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getSessionState() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSessionState');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error fetching session state: $e');
    }
    return {
      'isSessionActive': false,
      'isTestMode': false,
      'remainingSec': 0,
      'currentCycleIndex': 0,
      'aiAllowanceRemainingSec': 0,
      'whatsappAllowanceRemainingSec': 0,
      'utilityAllowanceRemainingSec': 0,
      'totalSessionMinutes': 0,
    };
  }

  static Future<void> openPureWriter() async {
    await _channel.invokeMethod('openPureWriter');
  }
}
