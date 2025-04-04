import 'package:flutter/material.dart';
import 'Util/notifications_helper.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'Models/task.dart';


class TestNotificationScreen extends StatefulWidget {
  @override
  _TestNotificationScreenState createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  // Create test tasks with proper IDs (use negative numbers for test IDs)
  final onceTask = Task(
    id: -1, // Temporary test ID
    name: "Test One-Time",
    taskType: "One-Time",
    durationType: "Minutes",
    notificationTime: DateTime.now().add(Duration(seconds: 20)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  final repeatTask = Task(
    id: -2, // Temporary test ID
    name: "Test Repetitive",
    taskType: "Repetitive",
    durationType: "Minutes",
    notificationTime: DateTime.now().add(Duration(seconds: 25)).millisecondsSinceEpoch,
    customInterval: 1,
  );

  Future<void> _sendOneTimeNotification() async {
    try {
      await NotificationHelper.scheduleNotification(onceTask);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("One-time notification scheduled!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"))
      );
    }
  }

  Future<void> _sendRepetitiveNotification() async {
    try {
      await NotificationHelper.scheduleNotification(repeatTask);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Repetitive notification scheduled!"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"))
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
          ],
        ),
      ),
    );
  }
}