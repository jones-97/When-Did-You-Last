import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../Util/database_helper.dart';
import '../Models/task.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();


  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? toneUri = prefs.getString('selectedRingtoneUri');

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'STOP') {
          debugPrint("Stop button pressed");
          await markTaskAsDone(response.id!);
        }

        if (response.actionId == 'PAUSE') {
          debugPrint("Pause button pressed");
          await pauseTask(response.id!);
        }
      },
    );

    // Create a notification channel for Android
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel_id', // Must match the channel ID in scheduleNotification
      'Task Notifications', // Channel name
      importance: Importance.high,
      sound: toneUri != null ? UriAndroidNotificationSound(toneUri) : null,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime, bool isRepeating) async {
    final prefs = await SharedPreferences.getInstance();

    final String? ringtoneUri = prefs.getString('selectedRingtoneUri');
    bool enableVibration =
        prefs.getBool('enableVibration') ?? true; // ✅ Default to true

    debugPrint("Scheduling notification for: $scheduledTime");
    debugPrint("Selected URI: $ringtoneUri");

     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'task_channel_id',
    'Task Notifications',
    channelDescription: 'Notifications for task reminders',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: enableVibration,
    vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
    sound: ringtoneUri != null ? UriAndroidNotificationSound(ringtoneUri) : null,
    actions: <AndroidNotificationAction>[
            const AndroidNotificationAction('STOP', 'Stop',
                showsUserInterface: true, cancelNotification: true),
            const AndroidNotificationAction('PAUSE', 'Pause',
                showsUserInterface: true, cancelNotification: true),
          ],
  );

  if (isRepeating) {
    // ✅ Use periodic notifications for repeating tasks
    await _notificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily, // ✅ Change to hourly if needed
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  } else {
    // ✅ Schedule a one-time notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_reminder',
    );
  }

  // static Future<void> scheduleTaskNotification(Task task) async {
  //   scheduleNotification(task.id!, "Task Reminder", "Don't forget: ${task.name}", scheduledTime, isRepeating)

  // }




    // await _notificationsPlugin.zonedSchedule(
    //   id,
    //   title,
    //   body,
    //   tz.TZDateTime.from(scheduledTime, tz.local),

    //   NotificationDetails(
    //     android: AndroidNotificationDetails(
    //       'task_channel_id', // Channel ID
    //       'Task Notifications', // Channel Name
    //       channelDescription:
    //           'Notifications for task reminders', // Channel Description
    //       importance: Importance.high,
    //       priority: Priority.high,
    //       playSound: true,

    //       /*  sound: ringtoneUri != null ? UriAndroidNotificationSound(ringtoneUri) // Use selected ringtone
    //       : const RawResourceAndroidNotificationSound('default_sound'),
    //         THIS IS ALREADY SPECIFIED ABOVE

    //   */
    //       enableVibration: enableVibration,
    //       vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
    //       //  sound: RawResourceAndroidNotificationSound('notification_sound'),
    //       actions: <AndroidNotificationAction>[
    //         const AndroidNotificationAction('STOP', 'Stop',
    //             showsUserInterface: true, cancelNotification: true),
    //         const AndroidNotificationAction('PAUSE', 'Pause',
    //             showsUserInterface: true, cancelNotification: true),
    //       ], // Add a custom sound if needed
    //     ),
    //     iOS: const DarwinNotificationDetails(
    //       sound: 'default', // Use default sound for iOS
    //     ),
    //   ),
    //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

     
  }


  //THIS METHOD BELOW IS NOT USED IN THE APP> SHOULD CLEAR IT
  
  static Future<void> scheduleTaskNotification(Task task) async {

    if (task.notificationTime != null) {
      await scheduleNotification(
        task.id!,
        "Task Reminder",
        "Don't forget: ${task.name}",
        DateTime.parse('2020'),
       true,
      );
    }
    
    // if (task.notifyDate != null) {
    //   await scheduleNotification(
    //     task.id!,
    //     "Task Reminder",
    //     "Don't forget: ${task.name}",
    //     DateTime.parse(task.notifyDate!),
    //    true,
    //   );
    // } else if (task.notifyHours != null) {
    //   await scheduleNotification(
    //     task.id!,
    //     "Task Reminder",
    //     "Don't forget: ${task.name}",
    //     DateTime.now().add(Duration(hours: task.notifyHours!)),
    //     true,
    //   );
    // } else if (task.notifyDays != null) {
    //   await scheduleNotification(
    //     task.id!,
    //     "Task Reminder",
    //     "Don't forget: ${task.name}",
    //     DateTime.now().add(Duration(days: task.notifyDays!)),
    //     true,
    //   );
    // }
  }
  

  static Future<void> requestNotificationPermissions(
      BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> markTaskAsDone(int taskId) async {
    final dbHelper = DatabaseHelper();
    final today = DateTime.now();
    final formattedDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    Task? task = await dbHelper.getTaskById(taskId);
    if (task != null) {
      await dbHelper.markTaskDone(taskId, formattedDate);
      debugPrint("Task $taskId marked as done on $formattedDate");
    }
  }

  static pauseTask(int taskId) async {
    final dbHelper = DatabaseHelper();

    await dbHelper.pauseTask(taskId);
  }
}
