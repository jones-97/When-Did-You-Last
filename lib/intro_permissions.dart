import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:when_did_you_last/home_page.dart';
import 'package:when_did_you_last/tutorial_screen.dart';

class IntroPermissionsScreen extends StatefulWidget {
  const IntroPermissionsScreen({super.key});

  @override
  State<IntroPermissionsScreen> createState() => _IntroPermissionsScreenState();
}

class _IntroPermissionsScreenState extends State<IntroPermissionsScreen> {
  bool _notificationGranted = false;
  bool _alarmGranted = false;
  bool _ignoresBatteryOptimizations = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidPlugin?.areNotificationsEnabled() ?? false;
      final alarmGranted = await androidPlugin?.requestExactAlarmsPermission() ?? false;

      final intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );

      // Check battery optimization status
      final status = await Permission.ignoreBatteryOptimizations.status;
      final ignoresBattery = status.isGranted;

      setState(() {
        _notificationGranted = granted;
        _alarmGranted = alarmGranted;
        _ignoresBatteryOptimizations = ignoresBattery;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await _requestNotificationPermission();
    await _checkExactAlarmPermission();

    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (!_notificationGranted) {
      await androidPlugin?.requestNotificationsPermission();
    }

    if (!_alarmGranted) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    if (_notificationGranted && _alarmGranted) {
         ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(elevation: 6,
            content: const Text("Sufficient Permissions Granted"),
            behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // adds space from bottom
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25), // pill shape
    ),
     // optional: make it pop
    
    duration: const Duration(seconds: 3),
            
            
            ));
    }

    await Permission.ignoreBatteryOptimizations.request();

    _checkPermissions(); // Update state
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _toggleBatteryOptimization() async {
    if (_ignoresBatteryOptimizations) {
      // Can't disable programmatically; only open the settings
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
    } else {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:com.example.when_did_you_last', // your package name
      );
      await intent.launch();
    }
    _checkPermissions();
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final introShown = prefs.getBool('intro_shown') ?? false;

    if (!introShown) {
      await prefs.setBool('intro_shown', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TutorialScreen()),
        );
      }
    } else {
      Navigator.pop(context); // or navigate to HomePage if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Permissions", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xff939dab)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("We need a few permissions to send reminders reliably:"),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(_notificationGranted ? Icons.check : Icons.notifications),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xffefd0d7),
              onPressed: _requestPermissions,
              child: const Text("Request Permissions"),
            ),
            const SizedBox(height: 12),
            MaterialButton(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
