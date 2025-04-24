import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'Util/notification_helper.dart';
import 'Util/database_helper.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  _AppLifecycleManagerState createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-initialize services when app returns to foreground
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    try {
      // Reinitialize notifications
      await NotificationHelper.init();
      
      // Cancel and reschedule all tasks
      await Workmanager().cancelAll();
      await _rescheduleAllTasks();
    } catch (e) {
      debugPrint("Error in app resume handling: $e");
    }
  }

  Future<void> _rescheduleAllTasks() async {
    final tasks = await DatabaseHelper().getTasks();
    for (final task in tasks) {
      if (task.notificationTime != null && 
          (task.taskType == "One-Time" || task.taskType == "Repetitive")) {
        await NotificationHelper.scheduleNotification(task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}