import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;

class IntroPermissionsScreen extends StatefulWidget {
  const IntroPermissionsScreen({super.key});

  @override
  State<IntroPermissionsScreen> createState() => _IntroPermissionsScreenState();
}

class _IntroPermissionsScreenState extends State<IntroPermissionsScreen> {
  bool _notificationGranted = false;
  bool _alarmGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidPlugin?.areNotificationsEnabled() ?? false;
      setState(() {
        _notificationGranted = granted;
      });

      // Exact alarm permission (Android 12+)
      final alarmGranted = await androidPlugin?.requestExactAlarmsPermission() ?? false;
      setState(() {
        _alarmGranted = alarmGranted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (!_notificationGranted) {
      await androidPlugin?.requestNotificationsPermission();
    }

    if (!_alarmGranted) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    setState(() {
      _checkPermissions();
    });
  }

  Future<void> _openBatteryOptimizationSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:com.example.when_did_you_last', // replace with your package name
    );
    await intent.launch();
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_shown', true);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/'); // go to home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Permissions")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("We need a few permissions to send reminders reliably:"),
            const SizedBox(height: 16),
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
            const Divider(),
            ElevatedButton(
              onPressed: _requestPermissions,
              child: const Text("Request Permissions"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _openBatteryOptimizationSettings,
              child: const Text("Disable Battery Optimization"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _completeSetup,
              child: const Text("Continue to App"),
            )
          ],
        ),
      ),
    );
  }
}
