import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:when_did_you_last/Util/notifications_helper_older.dart';
import 'package:when_did_you_last/app_lifecycle_manager.dart';
import 'package:when_did_you_last/home_page.dart';
import 'tutorial_screen.dart';
// import 'package:android_intent_plus/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class IntroPermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroPermissionsScreen({super.key, required this.onComplete});

  @override
  State<IntroPermissionsScreen> createState() => _IntroPermissionsScreenState();
}

class _IntroPermissionsScreenState extends State<IntroPermissionsScreen> {
  bool _notificationGranted = false;
  bool _alarmGranted = false;
  bool _ignoresBatteryOptimizations = false;

  //older
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      setState(() => _isLoading = true);

      // Check notification permission
      final notificationAllowed =
          await AwesomeNotifications().isNotificationAllowed();

      // Check exact alarm permission (Android 12+)
      bool alarmAllowed = false;
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        alarmAllowed = await Permission.scheduleExactAlarm.isGranted;
      } else {
        alarmAllowed = true; // Not needed below Android 12
      }

      // Check battery optimization status
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

      setState(() {
        _notificationGranted = notificationAllowed;
        _alarmGranted = alarmAllowed;
        _ignoresBatteryOptimizations = batteryStatus.isGranted;
        _isLoading = false;
      });
    }
  }

 Future<void> _requestPermissions() async {
  setState(() => _isLoading = true);
  
  try {
    // Only show explanation dialog if permissions were previously denied
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      final proceed = await showPermissionExplanationDialog();
      if (!proceed) return;
    }
    
    await _requestNotificationPermission();
    await NotificationHelper().askForNotificationPermissions();
    await _checkExactAlarmPermission();
    await _isBatteryOptimizationDisabled();
    
  } finally {
    setState(() => _isLoading = false);
    _checkPermissions(); // Refresh UI state
  }
}

Future<bool> showPermissionExplanationDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.info),
      title: Text("Permissions Needed"),
      content: Text("We need these permissions for better app functionality."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("Not Now"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Continue"),
        ),
      ],
    ),
  ) ?? false;
}

  //IGNORE
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }


  Future<void> _requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      // Notification permissions granted
    } else if (status.isDenied) {
      // Notification permissions denied
      // await showPermissionExplanationDialog();
    } else if (status.isPermanentlyDenied) {
      // Notification permissions permanently denied, open app settings
      await openAppSettings();
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<bool> _isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  Future<void> _toggleBatteryOptimization() async {
    try {
      await AppSettings.openAppSettings(
          type: AppSettingsType.batteryOptimization);
      await Future.delayed(const Duration(seconds: 1));
      await _checkPermissions(); // Refresh status
    } catch (e) {
      await AppSettings.openAppSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Couldn't open settings safely: ${e.toString()}")),
      );
    }
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('intro_shown', true);

    widget.onComplete();

    // Then navigate based on tutorial completion
  if (prefs.getBool('tutorial_completed') != true) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TutorialScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppLifecycleManager(child: const MyHomePage()),
      ),
    );
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Setup Permissions",
              style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff939dab)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("We need a few permissions to send reminders reliably:"),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                  _notificationGranted ? Icons.check : Icons.notifications),
              title: const Text("Notification Permission"),
              subtitle: const Text("To show reminders"),
            ),
            ListTile(
              leading: Icon(_alarmGranted ? Icons.check : Icons.alarm),
              title: const Text("Exact Alarm Permission"),
              subtitle: const Text("To schedule exact reminders (Android 12+)"),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            MaterialButton(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xffefd0d7),
              onPressed: _requestPermissions,
              child: const Text("Request Permissions"),
            ),
            const SizedBox(height: 12),
            MaterialButton(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xffefd0d7),
              onPressed: _toggleBatteryOptimization,
              child: Text(_ignoresBatteryOptimizations
                  ? "Re-enable Battery Optimization"
                  : "Disable Battery Optimization"),
            ),
            const Spacer(),
            MaterialButton(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xfffcaeae2),
              onPressed: _completeSetup,
              child: const Text("Continue to App"),
            )
          ],
        ),
      ),
    );
  }
}
