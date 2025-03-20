import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

 static Future<void> init() async {
  tz.initializeTimeZones();

  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iOSInitSettings =
      DarwinInitializationSettings();

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iOSInitSettings,
  );

  await _notificationsPlugin.initialize(initSettings);
}

  static Future<void> scheduleNotification(
  int id, String title, String body, DateTime scheduledTime) async {
  await _notificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel_id', // Channel ID
        'Task Notifications', // Channel Name
        channelDescription: 'Notifications for task reminders', // Channel Description
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'), // Add a custom sound if needed
      ),
      iOS: DarwinNotificationDetails(
        sound: 'default', // Use default sound for iOS
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
     // Ensure exact timing
    payload: 'task_reminder', // Optional payload
  );
}

static Future<void> requestNotificationPermissions(BuildContext context) async {
  if (Theme.of(context).platform == TargetPlatform.android) {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}

}
