import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleRampUpNotifications({
    required DateTime targetStartTime,
    required bool isTestMode,
  }) async {
    await cancelAllNotifications();

    if (isTestMode) {
      // In fast test mode, trigger warning 1 minute before
      final testWarnTime = targetStartTime.subtract(const Duration(minutes: 1));
      if (testWarnTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: 101,
          title: "🧪 [Test Mode] 1 Minute Warning",
          body: "Focus Sanctum lock will activate in 1 minute.",
          scheduledDate: testWarnTime,
        );
      }

      // T=0 Lockdown Engaged
      if (targetStartTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: 100,
          title: "🛡️ Focus Sanctum Lockdown Engaged!",
          body: "Test session started. Pure Writer is now active.",
          scheduledDate: targetStartTime,
          fullScreen: true,
        );
      }
      return;
    }

    final now = DateTime.now();
    final leadTimeMinutes = targetStartTime.difference(now).inMinutes;

    // T-30 minutes warning
    final t30 = targetStartTime.subtract(const Duration(minutes: 30));
    if (t30.isAfter(now)) {
      await _scheduleNotification(
        id: 101,
        title: "⏳ 30 Minutes Until Writing Session",
        body: "Your scheduled writing block starts soon. Prepare your mind.",
        scheduledDate: t30,
      );
    }

    // T-10 minutes warning
    final t10 = targetStartTime.subtract(const Duration(minutes: 10));
    if (t10.isAfter(now)) {
      await _scheduleNotification(
        id: 102,
        title: "⚠️ 10 Minutes Remaining",
        body: "Wrap up browser tabs and social feeds. Focus lock approaches.",
        scheduledDate: t10,
      );
    }

    // T-5 minutes warning
    final t5 = targetStartTime.subtract(const Duration(minutes: 5));
    if (t5.isAfter(now)) {
      await _scheduleNotification(
        id: 103,
        title: "🚨 5 Minutes Left!",
        body: "Final warning. Head into Pure Writer before the lockdown engages.",
        scheduledDate: t5,
      );
    }

    // If scheduled with short lead time (< 10 minutes), schedule T-1 minute warning
    if (leadTimeMinutes < 10) {
      final t1 = targetStartTime.subtract(const Duration(minutes: 1));
      if (t1.isAfter(now)) {
        await _scheduleNotification(
          id: 104,
          title: "🚨 1 Minute Remaining!",
          body: "Takeover begins in 60 seconds. Entering Pure Writer.",
          scheduledDate: t1,
        );
      }
    }

    // T=0 Full Phone Takeover Alarm Notification
    if (targetStartTime.isAfter(now)) {
      await _scheduleNotification(
        id: 100,
        title: "🛡️ Focus Sanctum Lockdown Engaged!",
        body: "Your writing session has begun. Pure Writer is now active.",
        scheduledDate: targetStartTime,
        fullScreen: true,
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool fullScreen = false,
  }) async {
    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'overseer_ramp_up',
          'Ramp-Up Warning Chimes',
          channelDescription: 'Notifications warning you before lockdown activates',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: fullScreen,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
