import 'package:flutter/material.dart';
import 'package:when_did_you_last/Util/database_helper.dart';
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
    name: "One-Time Notification TEST",
    taskType: "One-Time",
    durationType: "Minutes",
    notificationTime:
        DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  final repeatTask = Task(
    id: 202, // Temporary test ID
    name: "Manual Repetitive Notification TEST",
    taskType: "Repetitive",
    durationType: "Minutes",
    autoRepeat: false,
    notificationsEnabled: true,
    notificationTime:
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  final wmTask = Task(
    //THIS IS THE REAL 15-MIN ONE
    //wmTask == WorkManager Task
    //For workmanager purposes

    id: 312,
    name: "Real 15-MIN Payload Notification TEST",
    taskType: "Repetitive",
    durationType: "Minutes",
    notificationsEnabled: true,
    autoRepeat: true,
    notificationTime:
        DateTime.now().add(const Duration(minutes: 16)).millisecondsSinceEpoch,
        customInterval: 15
  );

  final payloadTask = Task(
  id: 402,
  name: "Auto-Repeat Simulation TEST",
  taskType: "Repetitive",
  durationType: "Minutes",
  autoRepeat: true, // keep this true to mimic a real scenario
  notificationsEnabled: true,
  notificationTime:
      DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch,
  customInterval: 1,
);



  Future<void> _sendOneTimeNotification() async {
    try {

          // Delete if already exists
    debugPrint("TESTNOTIF:: Deleting OneTime Notification ⏩ if exists ⏪ in Database");
    await DatabaseHelper().deleteTask(onceTask.id!);
  
  //Now insert fresh
      onceTask.notificationId = NotificationHelper.createUniqueNotificationId(onceTask.id!);
      debugPrint("TESTNOTIF:: Inserting OneTime Notification in Database");
      await DatabaseHelper().insertTask(onceTask);
      

      debugPrint("TESTNOTIF:: Scheduling OneTime Notification...");
      await NotificationHelper.scheduleNotification(onceTask);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("One-time notification scheduled!")));
          
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
          debugPrint("TESTNOTIF:: ERROR Scheduling OneTime Notification: ${e.toString()}");
    }
  }

  Future<void> _sendRepetitiveNotification() async {
    try {
          // Delete if already exists
    debugPrint("TESTNOTIF:: Deleting Manual Repetitive Notification ⏩ if exists ⏪ in Database...");
    await DatabaseHelper().deleteTask(repeatTask.id!);

    //now insert fresh
      repeatTask.notificationId = NotificationHelper.createUniqueNotificationId(onceTask.id!);
      debugPrint("TESTNOTIF:: Inserting Manual Repetitive Notification in Database...");
      debugPrint("TESTNOTIF:: MANUAL REPEAT TASK notification id is: ${repeatTask.notificationId.toString()}");
      await DatabaseHelper().insertTask(repeatTask);

      debugPrint("TESTNOTIF:: Scheduling Manual Repetitive Notification in Database...");
      await NotificationHelper.scheduleNotification(repeatTask);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Repetitive notification scheduled!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
          debugPrint("TESTNOTIF:: Error Scheduling Manual Repetitive Notification: ${e.toString()}");
    }
  }

  
  Future<void> _sendWMNotification() async {
    //THIS IS FOR THE REAL WORKMANAGER NOTIFICATION OF 15-MIN

    try {
          // Delete if already exists
    debugPrint("TESTNOTIF:: Deleting REAL WORKMANAGER Notification ⏩ if exists ⏪in Database...");
    await DatabaseHelper().deleteTask(wmTask.id!);

    //insert fresh
      wmTask.notificationId = NotificationHelper.createUniqueNotificationId(onceTask.id!);
      debugPrint("TESTNOTIF:: Inserting ⬇ REAL WORKMANAGER Notification in Database...");
      await DatabaseHelper().insertTask(wmTask);

      debugPrint("TESTNOTIF:: Scheduling 🕖 REAL WORKMANAGER Notification in Database...");
      await NotificationHelper.scheduleNotification(wmTask);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payload test notification scheduled!")));
    } catch (e) {
      debugPrint("Error scheduling payload notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error with payload: ${e.toString()}")));
          debugPrint("TESTNOTIF:: ERROR SCheduling REAL WORKMANAGER Notification: ${e.toString()}");
    }
  }



    Future<void> _sendPayloadNotification() async {
  try {
        // Delete if already exists
    debugPrint("TESTNOTIF:: Deleting FAKE SIMULATED PAYLOAD Notification ⏩ if exists ⏪ in Database...");
    await DatabaseHelper().deleteTask(payloadTask.id!);

    //insert fresh
    payloadTask.notificationId = NotificationHelper.createUniqueNotificationId(onceTask.id!);
    debugPrint("TESTNOTIF:: Inserting FAKE SIMULATED PAYLOAD Notification in Database...");
    await DatabaseHelper().insertTask(payloadTask);

    debugPrint("TESTNOTIF:: Scheduling 🕗 FAKE SIMULATED PAYLOAD Notification in Database...");
    await NotificationHelper.scheduleNotification(payloadTask);

    //REMOVED BUT WORKS. FOR SIMULATION ONLY.
    //TEST REAL WORKMANAGER NOTIF IN _sendWMTaskNotification

    // Simulate WorkManager by manually triggering repeat every 30s

    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));

      final task = await DatabaseHelper().getTaskById(payloadTask.id!);
      if (task == null || !task.notificationsEnabled || !task.autoRepeat || !task.isActive) {
        debugPrint("🛑 Auto-repeat simulation stopped.");
        return false; // stop repeating
      }

      final nextTime = DateTime.now().add(const Duration(seconds: 10));
      final updated = task.copyWith(notificationTime: nextTime.millisecondsSinceEpoch);

      debugPrint("🔁 Simulating auto-repeat for task ${task.id} at ${nextTime.toIso8601String()}");
      await NotificationHelper.scheduleNotification(updated);

      return true; // continue repeating
      
    }
    
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Simulated auto-repeat started!")),
    );
  } catch (e) {
    debugPrint("Error scheduling simulated auto-repeat: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error with payload: ${e.toString()}")),
    );
    debugPrint("TESTNOTIF:: ERROR Scheduling FAKE PAYLOAD Notification: ${e.toString()}");
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
                onPressed: _sendWMNotification,
                child: const Text("Send ACTUAL WORKMANAGER payload notification")),
          ],
        ),
      ),
    );
  }
}
