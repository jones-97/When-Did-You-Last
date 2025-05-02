import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../Util/database_helper.dart';
import '../Models/task.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  debugPrint("✅ Background action received: ${response.actionId}");

  if (response.id != null) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(response.id!);
  }

  final payload = response.payload;
  if (payload == null) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final int taskId = data['taskId'];

    final db = DatabaseHelper();
    final task = await db.getTaskById(taskId);

    if (task == null) return;

    switch (response.actionId) {
      case 'continue_action':
        debugPrint("📆 Background: Rescheduling task $taskId");

        if (!task.autoRepeat && task.taskType == "Repetitive") {
          final nextTime = DateTime.now().add(Duration(
            hours: task.durationType == 'Hours' ? task.customInterval ?? 1 : 0,
            days: task.durationType == 'Days' ? task.customInterval ?? 1 : 0,
          ));

          final updated = task.copyWith(notificationTime: nextTime.millisecondsSinceEpoch);

          await db.updateTask(updated);
          await NotificationHelper2.scheduleNotification(updated);
        }
        break;

      case 'stop_action':
        debugPrint("⛔ Background: Stopping task $taskId");

        await db.updateTask(task.copyWith(notificationsEnabled: false));
        await Workmanager().cancelByUniqueName("repeating_task_$taskId");
        break;

      default:
        debugPrint("⚠️ Unknown action in background: ${response.actionId}");
    }
  } catch (e) {
    debugPrint("❌ Background handler error: $e");
  }
}


class NotificationHelper2 {
  static bool _isInitialized = false;
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;


  

  static Future<void> init() async {
    if (_isInitialized) return;
    await _initializeImpl();
    _isInitialized = true;
  }

   // Special initialization for background isolates
  @pragma('vm:entry-point')
  static Future<void> initializeForBackground() async {
    if (_isInitialized) return;
    await _initializeImpl();
    _isInitialized = true;
  }


  static Future<void> _initializeImpl() async {

    

    _notificationsPlugin = FlutterLocalNotificationsPlugin();


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

    await _notificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: handleNotificationAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

    await _notificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

        _isInitialized = true;
  }

  static Future<void> scheduleNotification(Task task) async {
    if (!_isInitialized) {
        await init();
      }

    if (task.notificationTime == null) return;
    assert(_notificationsPlugin != null, 
      'NotificationHelper must be initialized before use');

    debugPrint("""
Scheduling Notification:
- ID: ${task.id}
- Name: ${task.name}
- Time: ${DateTime.fromMillisecondsSinceEpoch(task.notificationTime!)}
- Type: ${task.taskType}
""");

    // For testing, allow negative IDs
    if (task.id == null || task.id! < 0) {
      debugPrint("Task ID must be set and positive");
      return;
    }

    // Create a payload map containing all necessary task info
    final payloadString = jsonEncode({
  'taskId': task.id,
  'taskType': task.taskType,
  'durationType': task.durationType,
  'customInterval': task.customInterval,
});

   

    final isRepetitive = task.taskType == "Repetitive";
    final scheduledTime =
        DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);

    // Debug prints
    debugPrint(
        "Scheduling ${isRepetitive ? 'Repetitive' : 'One-Time'} notification");
    debugPrint("Scheduled time: $scheduledTime");
    debugPrint("Current time: ${DateTime.now()}");

    // Notification details
    final androidDetails =
        AndroidNotificationDetails('task_channel_id', 'Task Notifications',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            actions: isRepetitive
                ? [
                    const AndroidNotificationAction(
                      'continue_action', // Changed from 'CONTINUE'
                      'Continue',
                      cancelNotification: true,
                      showsUserInterface: false,
                    ),
                    const AndroidNotificationAction(
                      'stop_action', // Changed from 'STOP'
                      'Stop',
                      cancelNotification: true,
                      showsUserInterface: false,
                    ),
                  ]
                : [
                    const AndroidNotificationAction(
                      'ok_action', // Changed from 'OK'
                      'OK',
                      cancelNotification: true,
                      showsUserInterface: false,
                    ),
                  ]);

    
    try {
      if (isRepetitive) {
        if (task.autoRepeat) {
          // Automatic repeating - use Workmanager
          Duration frequency;
          switch (task.durationType) {
            case "Minutes":
              frequency = Duration(minutes: max(task.customInterval ?? 15, 15));
              break;
            case "Hours":
              frequency = Duration(hours: task.customInterval ?? 1);
              break;
            case "Days":
              frequency = Duration(days: task.customInterval ?? 1);
              break;
            default:
              frequency = Duration(hours: 1);
          }

          await Workmanager().registerPeriodicTask(
            "repeating_task_${task.id}",
            "repeatingTask",
            frequency: frequency,
            inputData: {'taskId': task.id},
            constraints: Constraints(networkType: NetworkType.not_required),
          );
        }
        // For manual repeat, don't register with Workmanager
        // Just schedule the single notification

        await _notificationsPlugin!.zonedSchedule(
          task.id!,
          task.name,
          task.details ?? 'Task reminder',
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payloadString,

          //For automatic rescheduling
          //   callback: (id) async {
          //   if (task.taskType == "Repetitive") {
          //     await rescheduleTask(task.id!);
          //   }
          // },
        );
      } else {
        await _notificationsPlugin!.zonedSchedule(
          task.id!,
          task.name,
          task.details ?? 'Task reminder',
          tz.TZDateTime.from(scheduledTime, tz.local),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payloadString,
        );
      }
      debugPrint("Notification scheduled successfully!");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
      rethrow;
    }
  }

  static Future<void> handleNotificationAction(
      NotificationResponse response) async {
    final notificationId = response.id;
    if (notificationId != null) {
      await _notificationsPlugin!.cancel(notificationId);
    }

    debugPrint("Foreground notification action: ${response.actionId}");

    if (response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction &&
        response.actionId != null &&
        response.id != null) {
      // ✅ Immediately cancel to ensure the tile disappears
      await _notificationsPlugin!.cancel(response.id!);
    }

  final payload = response.payload;
if (payload == null) return;

Map<String, dynamic> data;
try {
  data = jsonDecode(payload);
} catch (e) {
  debugPrint("Error decoding JSON payload: $e");
  return;
}

final int? taskId = data['taskId'];
if (taskId == null) {
  debugPrint("Missing taskId in payload.");
  return;
}




    final db = DatabaseHelper();
    final task = await db.getTaskById(taskId!);
    if (task == null) return;

    switch (response.actionId) {
      case 'ok_action':
        debugPrint("PRESSED OK IN NOTIFICATIONS!");
        await cancelNotification(taskId);
        debugPrint("User acknowledged task $taskId");
        break;

      case 'continue_action':
      debugPrint("PRESSED CONTINUE IN NOTIFICATIONS!");
        // ✅ Repeat logic (assumes task is repetitive and not paused)
//       if (task.taskType == 'Repetitive' && !task.notificationsPaused) {
//         final nextTime = DateTime.now().add(Duration(
//           hours: task.durationType == 'Hours' ? task.customInterval! : 0,
//           days: task.durationType == 'Days' ? task.customInterval! : 0,
//         ));

//         final updated = task.copyWith(notificationTime: nextTime.millisecondsSinceEpoch);
//         await db.updateTask(updated);
//         await scheduleNotification(updated);
//       }

//       if (payload == 'continue') {
//   Task? task = await DatabaseHelper().getTaskById(taskId);
//   if (task != null) {
//     // Schedule the next instance
//     await NotificationHelper.scheduleNotification(task);
//   }
// }
        if (task.taskType == 'Repetitive' && task.notificationsEnabled) {
          if (!task.autoRepeat) {
            // Only reschedule if user confirms (autoRepeat is false)
            final nextTime = DateTime.now().add(Duration(
              hours: task.durationType == 'Hours' ? task.customInterval! : 0,
              days: task.durationType == 'Days' ? task.customInterval! : 0,
            ));

            final updated = task.copyWith(
                notificationTime: nextTime.millisecondsSinceEpoch);
            await db.updateTask(updated);
            await scheduleNotification(updated);
          }
          // If autoRepeat is true, Workmanager will handle it
        }
        break;

      case 'stop_action':
      debugPrint("PRESSED STOP IN NOTIFICATIONS!");
        // Cancel both notification and Workmanager
      await cancelNotification(taskId);
      await Workmanager().cancelByUniqueName("repeating_task_$taskId");
      await db.updateTask(task.copyWith(notificationsEnabled: false));
      break;

      default:
        debugPrint("Unknown action: ${response.actionId}");
    }
  }

  static Future<void> rescheduleTask(int taskId) async {
    try {
      await cancelNotification(taskId);

      final dbHelper = DatabaseHelper();
      final task = await dbHelper.getTaskById(taskId);
      if (task == null || task.customInterval == null) return;

      // Calculate new notification time based on original interval
      final now = DateTime.now();
      final originalNotificationTime =
          DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
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
    } catch (e) {
      debugPrint("Error in rescheduleTask: $e");
    }
  }

  static Future<void> stopTask(int taskId) async {
    try {
      await cancelNotification(taskId);

      final dbHelper = DatabaseHelper();
      await dbHelper.updateTask(
        (await dbHelper.getTaskById(taskId))!.copyWith(
          notificationsEnabled: false,
        ),
      );
      // await Workmanager().cancelByUniqueName("repeating_task_$taskId");
    } catch (e) {
      debugPrint("Error stoping the task from notification: $e");
    }
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
    await _notificationsPlugin!.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin!.cancelAll();
  }

  static Future<void> _rescheduleRepetitiveTask(int taskId) async {
    final dbHelper = DatabaseHelper();
    final task = await dbHelper.getTaskById(taskId);

    if (task == null || task.taskType != "Repetitive") return;

    // Calculate next occurrence based on original interval
    final nextTime = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!)
        .add(task.durationType == "Hours"
            ? Duration(hours: task.customInterval ?? 1)
            : Duration(days: task.customInterval ?? 1));

    // Update task with new time
    await dbHelper.updateTask(task.copyWith(
      notificationTime: nextTime.millisecondsSinceEpoch,
    ));

    // Schedule the next notification
    await scheduleNotification(task.copyWith(
      notificationTime: nextTime.millisecondsSinceEpoch,
    ));
  }

  static Future<void> _cancelRepetitiveTask(int taskId) async {
    // Cancel the notification
    await cancelNotification(taskId);

    // Cancel the Workmanager background task
    await Workmanager().cancelByUniqueName("repeating_task_$taskId");

    // Update database (optional - mark as inactive instead of deleting)
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTask(
      (await dbHelper.getTaskById(taskId))!.copyWith(
        notificationsEnabled: false, // Add this field to your Task model
      ),
    );
  }

  static Future<void> requestNotificationPermissions(
      BuildContext context) async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin!.resolvePlatformSpecificImplementation<
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

    await _notificationsPlugin!.show(
      0, // Use 0 as ID for test notifications
      'Test Notification',
      'This is a test notification to verify your app notifications are working',
      platformDetails,
      payload: 'test_notification',
    );
  }

  Future<void> _sendPayloadTestNotification() async {
    final testTask = Task(
      id: 2 * DateTime.now().millisecondsSinceEpoch.remainder(100000),
      name: "Test Notification",
      taskType: "One-Time",
      durationType: "Minutes",
      notificationTime:
          DateTime.now().add(Duration(seconds: 10)).millisecondsSinceEpoch,
    );

    await NotificationHelper2.scheduleNotification(testTask);
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
