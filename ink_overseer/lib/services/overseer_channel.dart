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

  static Future<void> scheduleSessionAlarm(int triggerAtMs) async {
    try {
      await _channel.invokeMethod('scheduleSessionAlarm', {
        'triggerAtMs': triggerAtMs,
      });
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error scheduling alarm: $e');
    }
  }

  static Future<void> cancelSessionAlarm() async {
    try {
      await _channel.invokeMethod('cancelSessionAlarm');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error cancelling alarm: $e');
    }
  }

  static Future<bool> launchPackage(String packageName) async {
    try {
      final res = await _channel.invokeMethod<bool>('launchPackage', {
        'packageName': packageName,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error launching package $packageName: $e');
      return false;
    }
  }

  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (res != null) {
        return res
            .map((item) => Map<String, String>.from(item as Map<dynamic, dynamic>))
            .toList();
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error getting installed apps: $e');
    }
    return [];
  }

  static Future<bool> setAllowedPackages(List<String> packages) async {
    try {
      final res = await _channel.invokeMethod<bool>('setAllowedPackages', {
        'packages': packages,
      });
      return res ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error setting allowed packages: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> getAllowedPackages() async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getAllowedPackages');
      if (res != null) {
        return res.cast<String>();
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Error getting allowed packages: $e');
    } catch (_) {}
    return [];
  }
}
