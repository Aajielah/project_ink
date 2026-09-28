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
      return;
    }

    // T-30 minutes warning
    final t30 = targetStartTime.subtract(const Duration(minutes: 30));
    if (t30.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 101,
        title: "⏳ 30 Minutes Until Writing Session",
        body: "Your scheduled writing block starts soon. Prepare your mind.",
        scheduledDate: t30,
      );
    }

    // T-10 minutes warning
    final t10 = targetStartTime.subtract(const Duration(minutes: 10));
    if (t10.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 102,
        title: "⚠️ 10 Minutes Remaining",
        body: "Wrap up browser tabs and social feeds. Focus lock approaches.",
        scheduledDate: t10,
      );
    }

    // T-5 minutes warning
    final t5 = targetStartTime.subtract(const Duration(minutes: 5));
    if (t5.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: 103,
        title: "🚨 5 Minutes Left!",
        body: "Final warning. Head into Pure Writer before the lockdown engages.",
        scheduledDate: t5,
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'overseer_ramp_up',
          'Ramp-Up Warning Chimes',
          channelDescription: 'Notifications warning you before lockdown activates',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
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
