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

    WidgetsFlutterBinding.ensureInitialized();
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
      onDidReceiveNotificationResponse: _handleNotificationAction,
      // (NotificationResponse response) async 
      // {
      //   final taskId = response.id;
      //   if (taskId == null) return;

      //   switch (response.actionId) {
      //     case 'OK':
      //       await markTaskAsDone(taskId);
      //       break;
      //     case 'CONTINUE':
      //       await rescheduleTask(taskId);
      //       break;
      //     case 'STOP':
      //       await stopTask(taskId);
      //       break;
      //     default:
      //       //HANDLE NOTIFICATION TAP WITHOUT ACTION
      //       debugPrint("Notification tapped with no action");
      //   }
      // },
      
    );

    // Create a notification channel for Android
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel_id', // Must match the channel ID in scheduleNotification
      'Task Notifications', // Channel name
      importance: Importance.max,
      sound: toneUri != null ? UriAndroidNotificationSound(toneUri) : null,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


static Future<void> scheduleNotification(Task task) async {
  if (task.notificationTime == null) return;

  
  
  debugPrint("""
Scheduling Notification:
- ID: ${task.id}
- Name: ${task.name}
- Time: ${DateTime.fromMillisecondsSinceEpoch(task.notificationTime!)}
- Type: ${task.taskType}
""");

  // For testing, allow negative IDs
  if (task.id == null || task.id! > 0) {
    debugPrint("Task ID must be set (can use negative numbers for testing)");
    return;
  }

  final isRepetitive = task.taskType == "Repetitive";
  final scheduledTime = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);

  // Debug prints
  debugPrint("Scheduling ${isRepetitive ? 'Repetitive' : 'One-Time'} notification");
  debugPrint("Scheduled time: $scheduledTime");
  debugPrint("Current time: ${DateTime.now()}");

  // Notification details
  final androidDetails = AndroidNotificationDetails(
    'task_channel_id',
    'Task Notifications',
    channelDescription: 'Notifications for task reminders',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    actions: isRepetitive
        ? [
        const AndroidNotificationAction(
          'continue_action',  // Changed from 'CONTINUE'
          'Continue',
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'stop_action',  // Changed from 'STOP'
          'Stop',
          cancelNotification: true,
        ),
      ]
    : [
        const AndroidNotificationAction(
          'ok_action',  // Changed from 'OK'
          'OK',
          cancelNotification: true,
        ),
      ]
  );

  try {
    if (isRepetitive) {
      await _notificationsPlugin.zonedSchedule(
        task.id!,
        task.name,
        task.details ?? 'Task reminder',
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: task.id.toString(),

        //For automatic rescheduling
      //   callback: (id) async {
      //   if (task.taskType == "Repetitive") {
      //     await rescheduleTask(task.id!);
      //   }
      // },
      );
    } else {
      await _notificationsPlugin.zonedSchedule(
        task.id!,
        task.name,
        task.details ?? 'Task reminder',
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id.toString(),
      );
    }
    debugPrint("Notification scheduled successfully!");
  } catch (e) {
    debugPrint("Error scheduling notification: $e");
    rethrow;
  }
}

static Future<void> _handleNotificationAction(NotificationResponse response) async {
  final taskId = int.tryParse(response.payload ?? '');
  if (taskId == null) return;

  try {
    switch (response.actionId) {
      case 'ok_action':  // Updated to match new ID
        await markTaskAsDone(taskId);
        break;
      case 'continue_action':  // Updated to match new ID
        await rescheduleTask(taskId);
        break;
      case 'stop_action':  // Updated to match new ID
        await stopTask(taskId);
        break;
      default:
        final task = await DatabaseHelper().getTaskById(taskId);
        if (task?.taskType == "One-Time") {
          await markTaskAsDone(taskId);
        }
    }
  } catch (e) {
    debugPrint("Error handling notification action: $e");
  }
}

static Future<void> rescheduleTask(int taskId) async {
  final dbHelper = DatabaseHelper();
  final task = await dbHelper.getTaskById(taskId);
  if (task == null || task.customInterval == null) return;

  // Calculate new notification time based on original interval
  final now = DateTime.now();
  final originalNotificationTime = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
  Duration interval;
  
  // Determine interval based on task type
  if (task.durationType == 'Days') {
    interval = Duration(days: task.customInterval!);
  } else if (task.durationType == 'Hours') {
    interval = Duration(hours: task.customInterval!);
  } else {
    interval = Duration(minutes: task.customInterval!);
  }

  // Calculate next notification time maintaining the original schedule
  DateTime nextNotificationTime = originalNotificationTime;
  while (nextNotificationTime.isBefore(now)) {
    nextNotificationTime = nextNotificationTime.add(interval);
  }

  // Update task in database
  await dbHelper.updateTask(task.copyWith(
    notificationTime: nextNotificationTime.millisecondsSinceEpoch,
  ));

  // Reschedule notification
  await scheduleNotification(task.copyWith(
    notificationTime: nextNotificationTime.millisecondsSinceEpoch,
  ));
}
    static Future<void> stopTask(int taskId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTask(
      (await dbHelper.getTaskById(taskId))!.copyWith(
        notificationsPaused: true,
      ),
    );
    await cancelNotification(taskId);
  }

  static Future<void> markTaskAsDone(int taskId) async {
    final dbHelper = DatabaseHelper();
    final today = DateTime.now();
    final formattedDate = today.toIso8601String();

    // For one-time tasks, mark as done and remove
    final task = await dbHelper.getTaskById(taskId);
    if (task != null) {
      await dbHelper.markTaskDone(taskId, formattedDate);
      // if (task.taskType == "One-Time") {
      //   await dbHelper.deleteTask(taskId);
       // For one-time tasks, optionally remove or archive them
    if (task.taskType == "One-Time") {
      await dbHelper.deleteTask(taskId);
      await cancelNotification(taskId);
    }
      
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
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


  static Future<void> sendTestNotification() async {
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'test_channel_id',
    'Test Notifications',
    channelDescription: 'Channel for testing notifications',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
    actions: [
      const AndroidNotificationAction(
        'test_action',
        'Got it!',
        cancelNotification: true,
      ),
    ],
  );

  NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await _notificationsPlugin.show(
    0, // Use 0 as ID for test notifications
    'Test Notification',
    'This is a test notification to verify your app notifications are working',
    platformDetails,
    payload: 'test_notification',
  );
}
    
      
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
  

  //THIS METHOD BELOW IS NOT USED IN THE APP> SHOULD CLEAR IT

  // static Future<void> scheduleTestNotification() async {
  //   if (task.notificationTime != null) {
  //     await scheduleNotification(
  //       task.id!,
  //       "Task Reminder",
  //       "Don't forget: ${task.name}",
  //       DateTime.parse('2020'),
  //       true,
  //     );
  //   }

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
 // }

  // static Future<void> requestNotificationPermissions(
  //     BuildContext context) async {
  //   if (Theme.of(context).platform == TargetPlatform.android) {
  //     final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
  //         _notificationsPlugin.resolvePlatformSpecificImplementation<
  //             AndroidFlutterLocalNotificationsPlugin>();

  //     if (androidPlugin != null) {
  //       await androidPlugin.requestNotificationsPermission();
  //     }
  //   }
  // }
  // )

  // static Future<void> cancelNotification(int id) async {
  //   await _notificationsPlugin.cancel(id);
  // }

  // static Future<void> markTaskAsDone(int taskId) async {
  //   final dbHelper = DatabaseHelper();
  //   final today = DateTime.now();
  //   final formattedDate =
  //       "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

  //   Task? task = await dbHelper.getTaskById(taskId);
  //   if (task != null) {
  //     await dbHelper.markTaskDone(taskId, formattedDate);
  //     debugPrint("Task $taskId marked as done on $formattedDate");
  //   }
  // }

  // static pauseTask(int taskId) async {
  //   final dbHelper = DatabaseHelper();

  //   await dbHelper.pauseTask(taskId);
  // }

