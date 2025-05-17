
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workmanager/workmanager.dart';
import '../Models/task.dart';
import '../Util/database_helper.dart';


class NotificationHelper {

  static bool _initialized = false;

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
      onNotificationDisplayedMethod: _handleAutoRepeatDisplay,
     
    onActionReceivedMethod: _onActionReceived,
  );

  _initialized = true;
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
        "🔍 Task loaded: $taskId, type=${task.taskType}, notifications status=${task.notificationsEnabled}, autoRepeat=${task.autoRepeat}");
    debugPrint(
        "🧪 durationType: ${task.durationType}, interval: ${task.customInterval}");

    try {
      // Cancel the notification first
      
     //  await cancelNotification(createUniqueNotificationId(taskId));
     await cancelNotification(taskId);

      switch (action.buttonKeyPressed) {
        case 'continue_action':
          debugPrint('Continue action for task $taskId');

          if (task.taskType == 'Repetitive') {
            debugPrint("✅ Task is repetitive");


            if (task.notificationsEnabled) {
              debugPrint("🔓 Notifications are enabled");


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
                await scheduleNotification(task);
              }
            } else {
              debugPrint("🚫 Skipping because notifications enabled is false");
            }
          } else {
            debugPrint("🚫 Skipping because task is not Repetitive");
          }

          break;

        case 'stop_action':
          debugPrint('Stop action for task $taskId');

          await DatabaseHelper()
              .updateTask(task.copyWith(notificationsEnabled: false, isActive: false));
          await markTaskAsDone(taskId);
          await Workmanager().cancelByUniqueName("repeating_task_$taskId");
          debugPrint("YOU HAVE STOPPED THIS TASK! 🛑");

          // Optionally mark task as paused in database
          // await DatabaseHelper().updateTask(task.copyWith(notificationsEnabled: false));
          break;

        case 'ok_action':
          debugPrint('OK action for task $taskId');
          await DatabaseHelper()
              .updateTask(task.copyWith(notificationsEnabled: false, isActive: false));
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

@pragma('vm:entry-point')
static Future<void> _handleAutoRepeatDisplay(ReceivedNotification notification) async {
  
    debugPrint('Notification ${notification.id} displayed - no rescheduling needed');

  // final taskId = int.tryParse(notification.payload?['taskId'] ?? '');
  // if (taskId == null) return;

  // final task = await DatabaseHelper().getTaskById(taskId);
  // if (task == null || !task.autoRepeat || !task.notificationsEnabled) return;

  // // Calculate next time based on original schedule, not current time
  // final originalTime = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
  // final nextTime = originalTime.add(Duration(
  //   minutes: task.durationType == 'Minutes' ? task.customInterval ?? 1 : 0,
  //   hours: task.durationType == 'Hours' ? task.customInterval ?? 1 : 0,
  //   days: task.durationType == 'Days' ? task.customInterval ?? 1 : 0,
  // ));

  // debugPrint("🔁 Auto-repeat scheduled at $nextTime after display");
  
  // // Update task with new notification time
  // final updated = task.copyWith(notificationTime: nextTime.millisecondsSinceEpoch);
  // await DatabaseHelper().updateTask(updated);
  
  // // Schedule the next notification
  // await NotificationHelper.scheduleNotification(updated);
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

/*
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
*/
  
  static Future<void> scheduleNotification(Task task, {bool rescheduleAfterTrigger = false}) async {
  if (task.notificationTime == null || !task.notificationsEnabled) return;

    await cancelNotification(task.id!);

  final isRepetitive = task.taskType == "Repetitive";
  final now = DateTime.now();

  DateTime scheduledTime = _calculateNextOccurrence(task, now);
  //DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
  

   // If notification is in the past and it's auto-repeat, schedule next occurrence
  if (scheduledTime.isBefore(now)) {
    if (task.autoRepeat && task.taskType == "Repetitive") {
      scheduledTime = _calculateNextOccurrence(task, now);
      final updated = task.copyWith(notificationTime: scheduledTime.millisecondsSinceEpoch);
      await DatabaseHelper().updateTask(updated);
      task = updated;
    } else {
      return; // Skip past one-time notifications
    }
  }

  final payload = {
    'taskId': task.id.toString(),
    'taskType': task.taskType,
    'durationType': task.durationType,
    if (task.customInterval != null) 'customInterval': task.customInterval.toString(),
  };

  try {
    debugPrint("📅 Scheduling notification for task ID ${task.id} at $scheduledTime");

    // Create the notification with appropriate buttons
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: task.id!,
        channelKey: 'task_channel',
        title: task.name,
        body: task.details ?? 'Task reminder',
        payload: payload,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true, // Add this to ensure notification appears
        //criticalAlert: true, // For iOS to show even in DND mode
      ),
      actionButtons: _getActionButtons(task),
      schedule:  task.autoRepeat
          ? NotificationInterval(
              interval: Duration(seconds: _getIntervalInSeconds(task)),
              repeats: true,
              preciseAlarm: true,
            )
          : NotificationCalendar.fromDate(
              date: scheduledTime,
              allowWhileIdle: true,
              preciseAlarm: true,
            ),
    );
  } catch (e, stack) {
    debugPrint("❌ Error in CREATING notification: $e");
    debugPrintStack(stackTrace: stack);
  }
}

static List<NotificationActionButton> _getActionButtons(Task task) {
  if (task.taskType != "Repetitive") {
    return [
      NotificationActionButton(
        key: 'ok_action',
        label: 'OK',
        actionType: ActionType.SilentAction,
        autoDismissible: true,
      ),
    ];
  }

  return task.autoRepeat
      ? [
          NotificationActionButton(
            key: 'stop_action',
            label: 'Stop',
            actionType: ActionType.SilentAction,
            autoDismissible: true,
          )
        ]
      : [
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
        ];
}
  static DateTime _calculateNextOccurrence(Task task, DateTime fromDate) {
  return fromDate.add(Duration(
    minutes: task.durationType == 'Minutes' ? task.customInterval ?? 1 : 0,
    hours: task.durationType == 'Hours' ? task.customInterval ?? 1 : 0,
    days: task.durationType == 'Days' ? task.customInterval ?? 1 : 0,
  ));
}

static int _getIntervalInSeconds(Task task) {
  switch (task.durationType) {
    case "Minutes":
      return (task.customInterval ?? 1) * 60;
    case "Hours":
      return (task.customInterval ?? 1) * 3600;
    case "Days":
      return (task.customInterval ?? 1) * 86400;
    default:
      return 60; // Default to 1 minute
  }
}
  
  
  Future<void> showAutoRepeatNotification(Task task) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
  String firstRunKey = 'task_${task.id}_hasRun';

  bool hasRunBefore = prefs.getBool(firstRunKey) ?? false;

  final payload = {
    'taskId': task.id.toString(),
    'taskType': task.taskType,
    'durationType': task.durationType,
    if (task.customInterval != null) 'customInterval': task.customInterval.toString(),
  };


  String bodyMessage = hasRunBefore
      ? task.details == null ? "⏰ Time to do your task again!" : "⏰ ${task.details}"
      : "🔔 Task started! This is the first notification to confirm it’s running.";
    
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: task.id!,  // Make sure this is unique per task
      channelKey: 'task_channel',
      title: task.name,
      body: bodyMessage,
      payload: payload,
      notificationLayout: NotificationLayout.Default,
    ),
    actionButtons: [NotificationActionButton(
                key: 'stop_action',
                label: 'Stop',
                actionType: ActionType.SilentAction,
                autoDismissible: true,
              ),]
  );
}

  @deprecated
  static Future<void> _createAutoRepeatNotification(Task task) async {


      final payload = {
    'taskId': task.id.toString(),
    'taskType': task.taskType,
    'durationType': task.durationType,
    if (task.customInterval != null) 'customInterval': task.customInterval.toString(),
  };

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: task.id!,
      channelKey: 'task_channel',
      title: task.name,
      body: task.details ?? 'Task reminder (Auto-Repeat)',
      payload: payload,
    ),
    
    actionButtons: [
      NotificationActionButton(
        key: 'continue_action',
        label: 'Continue',
        actionType: ActionType.SilentAction,
        //autoDismissible: true,
      ),
      NotificationActionButton(
        key: 'stop_action',
        label: 'Stop',
        actionType: ActionType.SilentAction,
        //autoDismissible: true,
      ),
    ],
  );
}


  @deprecated
  static Future<void> createImmediateNotification(Task task) async {
    //DIFFERENT FROM scheduleNotif(). This one handles autorepeating continuing tasks
    //UPDATE: NOT NEEDED; BRINGS CONFUSION
    
  final payload = {
    'taskId': task.id.toString(),
    'taskType': task.taskType,
    'durationType': task.durationType,
    if (task.customInterval != null) 'customInterval': task.customInterval.toString(),
  };

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: createUniqueNotificationId(task.id!),
      channelKey: 'task_channel',
      title: task.name,
      body: task.details ?? 'Task reminder',
      payload: payload,
    ),
    actionButtons: [
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
    ],
  );
}

  // 📍 A clean helper for enabling/disabling a task's notifications
static Future<void> updateNotificationState(Task task) async {
  if (!task.notificationsEnabled) {
    // 🚫 Notifications disabled
    await cancelNotification(task.id!);

    if (task.autoRepeat) {
    await cancelWorkManagerTask(task.id!); // For auto-repeat tasks if any
    }
    debugPrint("Notifications disabled for task ID: ${task.id}");
  } else {
    // ✅ Notifications enabled
    if (task.notificationTime != null) {
      await scheduleNotification(task);
      debugPrint("Notifications scheduled for task ID: ${task.id}");
    }
  }
}



  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelWorkManagerTask(int taskId) async {
  await Workmanager().cancelByUniqueName("repeating_task_$taskId");
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
      debugPrint("Marking ${task.name} as DONE of TASK TYPE: ${task.taskType} on COMPLETED DATE $formattedDate");

      if (task.taskType == "One-Time") {
      //  await dbHelper.deleteTask(taskId);
        await cancelNotification(taskId);
      }
    }
  }

  static Future<void> unmarkTaskAsDone(int taskId) async {
    final dbHelper = DatabaseHelper();
    final today = DateTime.now();
    final formattedDate = today.toIso8601String();

    final task = await dbHelper.getTaskById(taskId);
    if (task != null) {
      await dbHelper.unmarkTaskDone(taskId, formattedDate);
      debugPrint("Marking ${task.name} as DONE of TASK TYPE: ${task.taskType} on COMPLETED DATE $formattedDate");

      if (task.taskType == "One-Time") {
      //  await dbHelper.deleteTask(taskId);
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
