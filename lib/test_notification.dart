import 'package:flutter/material.dart';
import 'Util/notifications_helper.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  void _sendTestNotification() {
    NotificationHelper.scheduleNotification(
      999, // Unique test notification ID
      "Test Notification",
      "This is a test notification.",
      DateTime.now().add(const Duration(seconds: 5)),
      false, // Sends in 5 seconds
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Notification"), 
        backgroundColor: const Color.fromARGB(255, 196, 126, 28),),
      body: Center(
        child: ElevatedButton(
          onPressed: _sendTestNotification,
          child: const Text("Send Test Notification"),
        ),
      ),
    );
  }
}
