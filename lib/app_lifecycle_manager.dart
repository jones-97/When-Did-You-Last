import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:when_did_you_last/Util/database_helper.dart';
import 'package:workmanager/workmanager.dart';
import 'Util/notification_helper.dart';


class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  _AppLifecycleManagerState createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  bool _isInitialized = false;
  
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

/*
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only handle lifecycle events after intro is complete
      final prefs = Provider.of<SharedPreferences>(context, listen: false);
      if (prefs.getBool('intro_shown') ?? false) {
        _handleAppResume();
      }
    }
  }
*/

/*
  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed && _isInitialized) {
    //The three lines below were removed. This version is for debugging
      // final prefs = Provider.of<SharedPreferences>(context, listen: false);
      // if (prefs.getBool('intro_shown') ?? false) {
      //   _handleAppResume();
      // }
    _handleAppResume();
  } else if (state == AppLifecycleState.resumed) {
    _isInitialized = true;
  }
}
*/

  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _handleAppResume();
  }
}

/*
  Future<void> _handleAppResume() async {
    try {
      await NotificationHelper.init();
      await Workmanager().cancelAll();
      await _rescheduleAllTasks();
    } catch (e) {
      debugPrint("App resume error: $e");
    }
  }
  */

  // In app_lifecycle_manager.dart
Future<void> _rescheduleAllTasks() async {
  final tasks = await DatabaseHelper().getTasks();
  for (final task in tasks) {
    if (task.taskType == "No Alert/Tracker") return;

    if (task.notificationsEnabled && task.notificationTime != null) {
      await NotificationHelper.scheduleNotification(task);
      
      // Also reschedule with WorkManager if needed
      if (task.autoRepeat) {
        await Workmanager().registerOneOffTask(
          'repeat_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          'notification_task',
          inputData: {'taskId': task.id},
          initialDelay: Duration(
            minutes: task.durationType == 'Minutes' ? task.customInterval ?? 1 : 0,
            hours: task.durationType == 'Hours' ? task.customInterval ?? 1 : 0,
            days: task.durationType == 'Days' ? task.customInterval ?? 1 : 0,
          ),
        );
      }
    }
  }
}

  Future<void> _handleAppResume() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('intro_shown') ?? false) {
    try {
      await NotificationHelper.init();
      await _rescheduleAllTasks();
    } catch (e) {
      debugPrint("Resume error: $e");
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}