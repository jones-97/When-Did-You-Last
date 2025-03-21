import 'package:flutter/material.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_manager/flutter_ringtone_manager.dart';
// import 'package:ringtone_picker/ringtone_picker.dart';
import 'package:flutter_system_ringtones/flutter_system_ringtones.dart';
import 'package:provider/provider.dart';
import 'Util/theme_provider.dart';

class Settings extends StatefulWidget {
  //final Function(bool) onThemeChanged;

  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  TimeOfDay? _defaultTaskTime;
  String? _selectedRingtone;
  bool _enableVibration = true;
  bool _autoCompleteTasks = false;
  bool _darkMode = false;

  final flutterRingtoneManager = FlutterRingtoneManager();


  @override
  void initState() {
    super.initState();
    initPlatformState();
    _loadSettings();
  }

    Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  Future<void> _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultTaskTime = prefs.containsKey('defaultTaskTime')
          ? TimeOfDay(
              hour: prefs.getInt('defaultTaskHour') ?? 8,
              minute: prefs.getInt('defaultTaskMinute') ?? 0)
          : null;
      _selectedRingtone = prefs.getString('selectedRingtone') ?? "Default";
      _enableVibration = prefs.getBool('enableVibration') ?? true;
      _autoCompleteTasks = prefs.getBool('autoCompleteTasks') ?? false;
      _darkMode = prefs.getBool('darkMode') ?? false;
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
        _saveSetting('defaultTaskHour', pickedTime.hour);
        _saveSetting('defaultTaskMinute', pickedTime.minute);
      });
    }
  }

  Future<void> _pickRingtone() async {
    await FlutterSystemRingtones.getRingtoneSounds();
  }

  // Future<void> _toggleDarkMode(bool value) async {
  //   widget.onThemeChanged(value); //Notify main.dart
  //   setState(() {
  //     _darkMode = value;
  //     _saveSetting('darkMode', value);
  //   });

  // }

  @override
  Widget build(BuildContext context) {
  // final themeProvider = Provider.of<ThemeProvider>(context);

     return Consumer<ThemeProvider>(
    builder: (context, themeProvider, child) {
      return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"), 
        titleTextStyle: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Default Task Time"),
            subtitle: Text(_defaultTaskTime != null
                ? "${_defaultTaskTime!.format(context)}"
                : "Not Set"),
            trailing: const Icon(Icons.access_time),
            onTap: _pickDefaultTime,
          ),
          ListTile(
            title: const Text("Select Notification Ringtone"),
            subtitle: Text(_selectedRingtone ?? "Default"),
            trailing: const Icon(Icons.music_note),
            onTap: () {
              _pickRingtone();
              //flutterRingtoneManager.playNotification();
              // Placeholder for ringtone picker implementation
            },
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
            title: const Text("Auto-Complete Tasks"),
            subtitle: const Text("Mark task as done when due date passes"),
            value: _autoCompleteTasks,
            onChanged: (value) {
              setState(() {
                _autoCompleteTasks = value;
                _saveSetting('autoCompleteTasks', value);
              });
            },
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: _darkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
              setState(() {}); //toggle refresh of this ui
            },
          ),
        ],
      ),
    );
    }
     );
     
  }
  
}
