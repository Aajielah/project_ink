import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._();

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) {
      // Local notifications not supported on Windows/Linux desktop directly without extra setups,
      // so we disable them gracefully to prevent crashes.
      _initialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
      );

      await _plugin.initialize(
        initializationSettings,
      );

      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }
  }

  Future<void> showInstantNotification(int id, String title, String body) async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general_channel',
            'General Notifications',
            channelDescription: 'General updates and lifecycle events.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show instant notification: $e');
    }
  }

  Future<void> scheduleDaily12AMNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      final scheduledDate = _nextInstanceOf12AM();
      await _plugin.zonedSchedule(
        0,
        'Project Ink Reminder',
        "Today's writing target is not complete! You have 5 hours left in your grace period to write or set a Rest Day.",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Reminders',
            channelDescription: 'Reminders to log daily writing progress.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule daily reminder notification: $e');
    }
  }

  Future<void> cancelDaily12AMNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      await _plugin.cancel(0);
    } catch (e) {
      debugPrint('Failed to cancel daily reminder notification: $e');
    }
  }

  Future<void> scheduleDailyMorningNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      final scheduledDate = _nextInstanceOfTime(12, 0); // 12:00 PM
      await _plugin.zonedSchedule(
        1,
        'Morning Session Reminder',
        "Don't forget your morning writing target! Keep your momentum going.",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_reminder_channel',
            'Morning Reminders',
            channelDescription: 'Reminders to write during the morning session.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule morning reminder notification: $e');
    }
  }

  Future<void> cancelDailyMorningNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      await _plugin.cancel(1);
    } catch (e) {
      debugPrint('Failed to cancel morning reminder notification: $e');
    }
  }

  Future<void> scheduleDailyEveningNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      final scheduledDate = _nextInstanceOfTime(20, 0); // 8:00 PM
      await _plugin.zonedSchedule(
        2,
        'Evening Session Reminder',
        "Time for your evening writing session! Let's get some words down.",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'evening_reminder_channel',
            'Evening Reminders',
            channelDescription: 'Reminders to write during the evening session.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule evening reminder notification: $e');
    }
  }

  Future<void> cancelDailyEveningNotification() async {
    if (!_initialized) await init();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;

    try {
      await _plugin.cancel(2);
    } catch (e) {
      debugPrint('Failed to cancel evening reminder notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final DateTime nowLocal = DateTime.now();
    DateTime scheduledLocal =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day, hour, minute);
    if (scheduledLocal.isBefore(nowLocal)) {
      scheduledLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1, hour, minute);
    }
    return tz.TZDateTime.from(scheduledLocal, tz.local);
  }

  tz.TZDateTime _nextInstanceOf12AM() {
    return _nextInstanceOfTime(0, 0);
  }
}
