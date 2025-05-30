import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_system_ringtones/flutter_system_ringtones.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:provider/provider.dart';
import 'Util/theme_provider.dart';
import 'Util/ringtone_picker.dart';

// Add these keys for SharedPreferences
const String _selectedRingtoneUriKey = 'selectedRingtoneUri';
const String _selectedRingtoneTitleKey = 'selectedRingtoneTitle';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  TimeOfDay? _defaultTaskTime;
  List<Ringtone> _ringtones = [];
  String? _selectedRingtoneUri;
  String? _selectedRingtoneTitle;
  bool _enableVibration = true;
  bool _autoCompleteTasks = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadSettings();
      _loadRingtones();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('defaultTaskHour') &&
          prefs.containsKey('defaultTaskMinute')) {
        _defaultTaskTime = TimeOfDay(
          hour: prefs.getInt('defaultTaskHour') ?? 8,
          minute: prefs.getInt('defaultTaskMinute') ?? 0,
        );
      }

      _enableVibration = prefs.getBool('enableVibration') ?? true;
      _autoCompleteTasks = prefs.getBool('autoCompleteTasks') ?? false;

      // Load both URI and title
      _selectedRingtoneUri = prefs.getString(_selectedRingtoneUriKey);
      _selectedRingtoneTitle =
          prefs.getString(_selectedRingtoneTitleKey) ?? "Default";
    });
  }

  Future<void> _loadRingtones() async {
    List<Ringtone> ringtones = await FlutterSystemRingtones.getRingtoneSounds();
    setState(() {
      _ringtones = ringtones;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    }
  }

  Future<void> _pickDefaultTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _defaultTaskTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (pickedTime != null) {
      setState(() {
        _defaultTaskTime = pickedTime;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('defaultTaskHour', pickedTime.hour);
      await prefs.setInt('defaultTaskMinute', pickedTime.minute);
    }
  }

  Future<void> _toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableVibration', value);
    setState(() {
      _enableVibration = value;
    });
  }

  Future<void> _pickRingtone() async {
    final selectedRingtoneUri = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RingtonePickerScreen(selectedRingtoneUri: _selectedRingtoneUri),
      ),
    );

    if (selectedRingtoneUri != null && selectedRingtoneUri.isNotEmpty) {
      try {
        final ringtone =
            _ringtones.firstWhere((rt) => rt.uri == selectedRingtoneUri);
        setState(() {
          _selectedRingtoneUri = ringtone.uri;
          _selectedRingtoneTitle = ringtone.title;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedRingtoneUri', ringtone.uri);
        await prefs.setString('selectedRingtoneTitle', ringtone.title);
      } catch (e) {
        debugPrint("Failed to select custom ringtone");
        setState(() {
          _selectedRingtoneTitle = "Custom Ringtone";
        });
        _saveSetting(_selectedRingtoneUriKey, selectedRingtoneUri);
      }
    }
  }

/*
  void _openAndroidNotificationSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.CHANNEL_NOTIFICATION_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
     // package: 'com.example.when_did_you_last',

     arguments: <String, dynamic> {
        'android.provider.extra.APP_PACKAGE': 'com.example.when_did_you_last', // ✅ Replace with your actual package name
        'android.provider.extra.CHANNEL_ID': 'task_channel_id',
      },
      
    );
    await intent.launch();
  }
*/

  void _openAndroidNotificationSettings() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 26) {
      // Android 8.0+ — can open app notification settings
      const intent = AndroidIntent(
        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
        arguments: <String, dynamic>{
          'android.provider.extra.APP_PACKAGE':
              'com.example.when_did_you_last', // ✅ Your app package
        },
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } else {
      // Older versions: Just open application details
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.example.when_did_you_last',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
        backgroundColor: const Color(0xff534e81),
      ),
      body: ListView(
        children: [
          /*
          ListTile(
            title: const Text("Default Task Time"),
            subtitle: Text(_defaultTaskTime != null
                ? _defaultTaskTime!
                    .format(context) // ✅ Uses updated default time
                : "Set default time for dated tasks"),
            trailing: const Icon(Icons.access_time),
            onTap: _pickDefaultTime,
          ),

          ListTile(
            title: const Text("Select Notification Ringtone"),
            subtitle: Text(_selectedRingtoneTitle ?? "Default"),
            trailing: const Icon(Icons.music_note),
            onTap: _pickRingtone,
          ),
            */

          ListTile(
            title: const Text("Manage Notifications in System Settings"),
            subtitle: const Text("Customize sound, priority, and behavior"),
            trailing: const Icon(Icons.settings),
            onTap: _openAndroidNotificationSettings,
          ),
          SwitchListTile(
            title: const Text("Enable Vibration"),
            value: _enableVibration,
            onChanged: (value) {
              setState(() {
                _enableVibration = value;
                _saveSetting('enableVibration', value);
              });
            },
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider
                  .toggleTheme(value); // Provider will handle the UI update
            },
          ),
          ListTile(
            title: const Text("Revisit Battery Permissions"),
            subtitle: const Text(
                "Alter battery optimization settings. Results may vary with devices."),
            trailing: const Icon(Icons.settings),
            onTap: () async {
              const intent = AndroidIntent(
                action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
                flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
              );
              await intent.launch();
            },
          ),
          ListTile(
  title: const Text("Clear All Reminders"),
  subtitle: const Text("Deletes all saved reminders. This action cannot be undone."),
  trailing: const Icon(Icons.delete_forever, color: Colors.red),
  onTap: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete all reminders?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Implement actual data clearing logic, e.g., calling your database/service method
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All reminders cleared.")),
      );
    }
  },
),
ListTile(
  title: const Text("Export Reminders"),
  subtitle: const Text("Backup your reminders to a file"),
  trailing: const Icon(Icons.file_upload),
  onTap: () {
    // TODO: Implement export logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Export not yet implemented.")),
    );
  },
),
ListTile(
  title: const Text("Import Reminders"),
  subtitle: const Text("Restore reminders from a backup file"),
  trailing: const Icon(Icons.file_download),
  onTap: () {
    // TODO: Implement import logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Import not yet implemented.")),
    );
  },
),
ListTile(
  title: const Text("About"),
  subtitle: const Text("App version, developer info, and license"),
  trailing: const Icon(Icons.info_outline),
  onTap: () {
    showAboutDialog(
      context: context,
      applicationName: "When Did You Last",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(Icons.access_time),
      applicationLegalese: "© 2025 Your Name or Company",
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 15),
          child: Text("This app helps you track when you last did something."),
        ),
      ],
    );
  },
),

/*
ListTile(
  title: const Text("Background Activity Settings"),
  subtitle: const Text("Manually enable background activity for notifications."),
  trailing: const Icon(Icons.settings),
  onTap: () async {
    const intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:com.example.yourapp', // ✅ Replace with your actual package name
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  },
),
*/
        ],
      ),
    );
  }
}
