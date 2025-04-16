import 'package:flutter/material.dart';
import 'package:when_did_you_last/Util/database_helper.dart';
import 'Util/notifications_helper_old.dart';
import 'Util/notification_helper.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'Models/task.dart';

class TestNotificationScreen extends StatefulWidget {
  @override
  _TestNotificationScreenState createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  // Create test tasks with proper IDs (use negative numbers for test IDs)
  final onceTask = Task(
    id: 102, // Temporary test ID
    name: "Test One-Time",
    taskType: "One-Time",
    durationType: "Minutes",
    notificationTime:
        DateTime.now().add(const Duration(seconds: 20)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  final repeatTask = Task(
    id: 202, // Temporary test ID
    name: "Test Repetitive",
    taskType: "Repetitive",
    durationType: "Minutes",
    autoRepeat: false,
    notificationsPaused: false,
    notificationTime:
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  final ptTask = Task(
    //THIS IS THE REAL 15-MIN ONE
    id: 312,
    name: "Test Notification",
    taskType: "Repetitive",
    durationType: "Minutes",
    notificationsPaused: false,
    autoRepeat: true,
    notificationTime:
        DateTime.now().add(const Duration(minutes: 16)).millisecondsSinceEpoch,
        customInterval: 15
  );

  final payloadTask = Task(
  id: 402,
  name: "Test Auto-Repeat Simulation",
  taskType: "Repetitive",
  durationType: "Minutes",
  autoRepeat: true, // keep this true to mimic a real scenario
  notificationsPaused: false,
  notificationTime:
      DateTime.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch,
  customInterval: 1,
);



  Future<void> _sendOneTimeNotification() async {
    try {
  
      await DatabaseHelper().insertTask(onceTask);
      await NotificationHelper.scheduleNotification(onceTask);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("One-time notification scheduled!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _sendRepetitiveNotification() async {
    try {
      await DatabaseHelper().insertTask(repeatTask);
      await NotificationHelper.scheduleNotification(repeatTask);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Repetitive notification scheduled!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  
  Future<void> _sendPTNotification() async {
    //THIS IS FOR THE REAL PAYLOAD NOTIFICATION OF 15-MIN

    try {
      await DatabaseHelper().insertTask(ptTask);
      await NotificationHelper.scheduleNotification(ptTask);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payload test notification scheduled!")));
    } catch (e) {
      debugPrint("Error scheduling payload notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error with payload: ${e.toString()}")));
    }
  }



    Future<void> _sendPayloadNotification() async {
  try {
    await DatabaseHelper().insertTask(payloadTask);
    await NotificationHelper.scheduleNotification(payloadTask);

    // Simulate WorkManager by manually triggering repeat every 30s
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));

      final task = await DatabaseHelper().getTaskById(payloadTask.id!);
      if (task == null || task.notificationsPaused || !task.autoRepeat) {
        debugPrint("🛑 Auto-repeat simulation stopped.");
        return false; // stop repeating
      }

      final nextTime = DateTime.now().add(const Duration(seconds: 10));
      final updated = task.copyWith(notificationTime: nextTime.millisecondsSinceEpoch);

      debugPrint("🔁 Simulating auto-repeat for task ${task.id} at ${nextTime.toIso8601String()}");
      await NotificationHelper.scheduleNotification(updated);

      return true; // continue repeating
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Simulated auto-repeat started!")),
    );
  } catch (e) {
    debugPrint("Error scheduling simulated auto-repeat: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error with payload: ${e.toString()}")),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Notification"),
        backgroundColor: const Color.fromARGB(255, 196, 126, 28),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              color: const Color.fromARGB(255, 91, 232, 232),
              onPressed: _sendOneTimeNotification,
              child: const Text("Send One-Time Notification"),
            ),
            SizedBox(height: 20),
            MaterialButton(
              color: const Color.fromARGB(255, 171, 28, 196),
              onPressed: _sendRepetitiveNotification,
              child: const Text("Send Repetitive Notification"),
            ),
            SizedBox(height: 20),
            MaterialButton(
                color: const Color.fromARGB(255, 171, 134, 29),
                onPressed: _sendPayloadNotification,
                child: const Text("Send SIMULATED payload notification")),
                SizedBox(height: 20),
            MaterialButton(
                color: const Color.fromARGB(255, 226, 216, 188),
                onPressed: _sendPTNotification,
                child: const Text("Send ACTUAL WORKMANAGER payload notification")),
          ],
        ),
      ),
    );
  }
}
