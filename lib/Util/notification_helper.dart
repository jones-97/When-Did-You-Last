import 'dart:math';
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import '../Models/task.dart';
import '../Util/database_helper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {

  static Future<void> initializeForBackground() async {
    debugPrint("Initialize NOTIFICATIONS FOR BACKGROUND called");
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'task_channel',
        channelName: 'Task Notifications',
        channelDescription: 'Notifications for task reminders',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
      ),
    ],
  );

  // DO NOT request permissions here
  AwesomeNotifications().setListeners(
    onNotificationCreatedMethod: (ReceivedNotification notification) async {
      debugPrint('Notification created: ${notification.id}');
    },
    onNotificationDisplayedMethod: (ReceivedNotification notification) async {
      debugPrint('Notification displayed: ${notification.id}');
    },
    onActionReceivedMethod: _onActionReceived,
  );
}

  static Future<void> init() async {
    debugPrint("Initialize NOTIFICATIONS ONLY NO BACKGROUND called");
    await initializeForBackground();

    //Now we request permissions in the foreground ONLY
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    try {
      debugPrint('Action received - Button: ${action.buttonKeyPressed}');
      debugPrint('Full action payload: ${action.payload}');

      // Handle both button presses and notification taps
      if (action.buttonKeyPressed.isNotEmpty) {
        await _handleButtonAction(action);
      } else {
        // Handle notification tap if needed
        debugPrint('Notification tapped, not a button action');
      }
    } catch (e) {
      debugPrint('Error in _onActionReceived: $e');
    }
  }

  static Future<void> _handleButtonAction(ReceivedAction action) async {
    final taskId = int.tryParse(action.payload?['taskId'] ?? '');
    if (taskId == null) {
      debugPrint('Invalid task ID in payload');
      return;
    }

    final task = await DatabaseHelper().getTaskById(taskId);
    if (task == null) {
      debugPrint("No task acquired to handle notifications");
      debugPrint(
          "No task acquired. taskId from payload: $taskId, payload: ${action.payload}");
      return;
    }

    debugPrint(
        "🔍 Task loaded: $taskId, type=${task.taskType}, paused=${task.notificationsPaused}, autoRepeat=${task.autoRepeat}");
    debugPrint(
        "🧪 durationType: ${task.durationType}, interval: ${task.customInterval}");

    try {
      // Cancel the notification first
      await cancelNotification(createUniqueNotificationId(taskId));

      switch (action.buttonKeyPressed) {
        case 'continue_action':
          debugPrint('Continue action for task $taskId');

          if (task.taskType == 'Repetitive') {
            debugPrint("✅ Task is repetitive");
            if (!task.notificationsPaused) {
              debugPrint("🔓 Notifications are not paused");
              if (!task.autoRepeat) {
                debugPrint("🔁 Not auto-repeat mode, rescheduling...");

                //  final nextTime = DateTime.now().add(const Duration(seconds: 20));
                final nextTime = DateTime.now().add(Duration(
                  minutes: task.durationType == 'Minutes'
                      ? task.customInterval ?? 1
                      : 0,
                  hours: task.durationType == 'Hours'
                      ? task.customInterval ?? 1
                      : 0,
                  days: task.durationType == 'Days'
                      ? task.customInterval ?? 1
                      : 0,
                ));
                final updated = task.copyWith(
                  notificationTime: nextTime.millisecondsSinceEpoch,
                );

                debugPrint("📅 Next time: $nextTime");
                debugPrint(
                    "ATTEMPTING TO RESCHEDULE TASK BASED ON USER INPUT...");
                await scheduleNotification(updated);
              } else {
                debugPrint("🚫 Skipping because task is autoRepeat");
              }
            } else {
              debugPrint("🚫 Skipping because notificationsPaused is true");
            }
          } else {
            debugPrint("🚫 Skipping because task is not Repetitive");
          }

          break;

        case 'stop_action':
          debugPrint('Stop action for task $taskId');

          await DatabaseHelper()
              .updateTask(task.copyWith(notificationsPaused: true));
          await Workmanager().cancelByUniqueName("repeating_task_$taskId");
          debugPrint("YOU HAVE STOPPED THIS TASK! 🛑");

          // Optionally mark task as paused in database
          // await DatabaseHelper().updateTask(task.copyWith(notificationsPaused: true));
          break;

        case 'ok_action':
          debugPrint('OK action for task $taskId');
          await markTaskAsDone(taskId);
          debugPrint("YOU HAVE PRESSED okayyyy for THIS TASK! 📮");
          break;

        default:
          debugPrint('Unknown action: ❓❓❓ ${action.buttonKeyPressed}');
        
      }
    } catch (e) {
      debugPrint("Error in handleButtonAction:  $e");
      debugPrintStack(stackTrace: StackTrace.fromString(e.toString()));
    }
  }

  // // Additional tracking
  // debugPrint("Button Pressed: ${action.buttonKeyPressed}");
  // debugPrint("Payload: ${action.payload}");

  //    if (action.buttonKeyPressed.trim() == 'continue_action') {

  //     debugPrint("✅ Continue action triggered");
  //   } else if (action.buttonKeyPressed == 'stop_action') {

  //       debugPrint("🛑 Stop action triggered");
  //       }
  //       else {

  //       debugPrint("❓ Unknown buttonKeyPressed: ${action.buttonKeyPressed}");

  //   }
  // }

  static Future<void> scheduleNotification(Task task) async {
    if (task.notificationTime == null) return;

    final isRepetitive = task.taskType == "Repetitive";
    final scheduledTime =
        DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
    final now = DateTime.now();

    // For repetitive tasks with autoRepeat, use Workmanager
    if (isRepetitive && task.autoRepeat) {
      Duration frequency;
      switch (task.durationType) {
        case "Minutes":
          frequency = Duration(minutes: task.customInterval ?? 15);
          break;
        case "Hours":
          frequency = Duration(hours: task.customInterval ?? 1);
          break;
        case "Days":
          frequency = Duration(days: task.customInterval ?? 1);
          break;
        default:
          frequency = const Duration(hours: 1);
      }

      debugPrint(
          "📡 Registering periodic task with WorkManager for task ${task.id}");

      await Workmanager().registerPeriodicTask(
        "repeating_task_${task.id}",
        "repeatingTask",
        frequency: frequency,
        inputData: {'taskId': task.id},
        constraints: Constraints(networkType: NetworkType.not_required),
      );
    }

    // Create the notification payload
    final payload = {
      'taskId': task.id.toString(),
      'taskType': task.taskType,
      'durationType': task.durationType,
      if (task.customInterval != null)
        'customInterval': task.customInterval.toString(),
    };

    try {
      final newtaskid = createUniqueNotificationId(task.id!);
      debugPrint("Creating a notification with new Id: $newtaskid");

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: newtaskid,
          channelKey: 'task_channel',
          title: task.name,
          body: task.details ?? 'Task reminder',
          payload: payload,
        ),
        actionButtons: isRepetitive
            ? [
                NotificationActionButton(
                  key: 'continue_action',
                  label: 'Continue',
                  actionType: ActionType.SilentAction,
                  autoDismissible: true,
                ),
                NotificationActionButton(
                  key: 'stop_action',
                  label: 'Stop',
                  actionType: ActionType.SilentAction,
                  autoDismissible: true,
                ),
              ]
            : [
                NotificationActionButton(
                  key: 'ok_action',
                  label: 'OK',
                  actionType: ActionType.SilentAction,
                  autoDismissible: true,
                ),
              ],
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true, // Bypass Doze mode
          preciseAlarm: true, // Request exact timing
        ),
      );
    } catch (e, stack) {
      debugPrint("Error in CREATING notification: $e");
      debugPrintStack(stackTrace: stack);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  static Future<void> markTaskAsDone(int taskId) async {
    final dbHelper = DatabaseHelper();
    final today = DateTime.now();
    final formattedDate = today.toIso8601String();

    final task = await dbHelper.getTaskById(taskId);
    if (task != null) {
      await dbHelper.markTaskDone(taskId, formattedDate);
      if (task.taskType == "One-Time") {
        await dbHelper.deleteTask(taskId);
        await cancelNotification(taskId);
      }
    }
  }

  static int createUniqueNotificationId(int taskId) {
    final now = DateTime.now();
    return int.parse("$taskId${now.millisecondsSinceEpoch.remainder(100000)}");
  }
}
// final taskId = int.tryParse(action.payload?['taskId'] ?? '');
// if (taskId == null) return;

// final db = DatabaseHelper();
// final task = await db.getTaskById(taskId);
// if (task == null) return;
// debugPrint("Task name:  $task.name");

// // switch (action.buttonKeyPressed) {
// //   case 'continue':
// try {
//   debugPrint("CONTINUE PRESSED ON NOTIFICATION!");

//   if (task.taskType == 'Repetitive' && !task.notificationsPaused) {
//     if (!task.autoRepeat) {
//       final nextTime = DateTime.now().add(Duration(
//         minutes:
//             task.durationType == 'Minutes' ? task.customInterval ?? 1 : 0,
//         hours:
//             task.durationType == 'Hours' ? task.customInterval ?? 1 : 0,
//         days: task.durationType == 'Days' ? task.customInterval ?? 1 : 0,
//       ));

//       final updated = task.copyWith(
//         notificationTime: nextTime.millisecondsSinceEpoch,
//       );
//      // await db.updateTask(updated);
//       debugPrint("ATTEMPTING TO RESCHEDULE TASK BASED ON USER INPUT...");
//       await scheduleNotification(updated);

// }
// }
// } catch (e) {
//   debugPrint("Error occurred: $e");
// }

//case 'stop':
// debugPrint("STOP BUTTON PRESSED ON NOTIFICATION!");
// await db.updateTask(task.copyWith(notificationsPaused: true));
// await Workmanager().cancelByUniqueName("repeating_task_$taskId");

// case 'ok':
// debugPrint("OKKKK BUTTON PRESSED ON NOTIFICATION!");
// await markTaskAsDone(taskId);
