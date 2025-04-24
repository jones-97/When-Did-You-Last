import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
// import 'Data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:when_did_you_last/Util/loading_screen.dart';
import 'package:when_did_you_last/app_lifecycle_manager.dart';
import 'package:when_did_you_last/intro_permissions.dart';
import 'package:workmanager/workmanager.dart';
// import 'dart:io';
// import 'package:when_did_you_last/settings.dart';
import 'package:provider/provider.dart';
import 'Models/task.dart';
import 'Util/theme_provider.dart';
import 'Util/database_helper.dart';
import 'Util/notification_helper.dart';
// import 'dart:io';
import 'home_page.dart'; // Import the new home.dart file

late final SharedPreferences prefs;

//late var _notificationsPlugin;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/* Future<void> requestNotificationPermissions(BuildContext context) async {
  if (Theme.of(context).platform == TargetPlatform.android) {
    
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}
*/

Future<bool> _loadEverything() async {
    await _initializeAppServices();
    return true;
  }

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

void handleNotificationResponse(String payload) async {
  List<String> parts = payload.split(":");
  int taskId = int.parse(parts[1]);

  // Cancel the notification first so it disappears
  await NotificationHelper.cancelNotification(taskId); // <-- Add this line

  if (parts[0] == "STOP") {
    await NotificationHelper.cancelNotification(taskId);
  } else if (parts[0] == "CONTINUE") {
    Task? task = await DatabaseHelper().getTaskById(taskId);
    if (task != null) {
      await NotificationHelper.scheduleNotification(task);
    }
  }
}

/*
Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
*/

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized(); 
    // Ensures Flutter is fully initialized
    
    prefs = await SharedPreferences.getInstance();
    final introShown = prefs.getBool('intro_shown') ?? false;

    await _initializeAppServices();

    runApp(ChangeNotifierProvider(
        create: (context) => ThemeProvider(), child: MyApp(showIntro: !introShown))
        );
  
    //   if (Platform.isWindows || Platform.isLinux) {
    //   // Initialize FFI
    //   sqfliteFfiInit();
    // }
  } catch (e) {
    debugPrint("Problem initializing the whole app:  $e");
  }
}

Future<void> _initializeAppServices() async {
  try {
    if (!kIsWeb) {
      tz.initializeTimeZones();

      await NotificationHelper.init();

      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

      //CHANGE THE 'true' IN THE ABOVE TO 'false' WHEN READY

      //Request PERMISSIONS:
      //THESE THREE COMMENTED OUT BECAUSE MOVED TO PERMISSIONS SCREEN

    //   await _requestNotificationPermission();
    //   await _checkExactAlarmPermission();
    // //  await _requestExactAlarmPermission();
    //   _requestBatteryOptimization();
    }

    // Initialize the database before running the app
    // A default db already implemented for android; for web, below is applied:
    if (kIsWeb) {
      // running on the web!
      databaseFactory = databaseFactoryFfiWeb;
      //Ensures IndexedDB is properly used because of persistence issues (remembering data) on the web
    }
    await Future.delayed(const Duration(seconds: 2));
  } catch (e) {
    debugPrint("FAilure intiailizing app services, THE FAILURE: $e");
  }

}

Future<void> _requestBatteryOptimization() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  if (androidInfo.version.sdkInt >= 23) {
    const intent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data:
          'package:com.example.when_did_you_last', // ✅ Replace with your app's package name
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      tz.initializeTimeZones();

      // Initialize notifications plugin in this isolate
      
      await NotificationHelper.initializeForBackground();

      // Keep background service alive
      int? taskId = inputData?['taskId'];

      if (taskId != null) {
        final task = await DatabaseHelper().getTaskById(taskId);
        if (task != null && task.autoRepeat && !task.notificationsPaused) {
          await NotificationHelper.scheduleNotification(task);
          debugPrint("📡 WorkMANAGER periodic task SET FROM MAIN with WorkManager for task ${task.id}");

        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Running background task with workmanager failed: $e");
      return Future.error(e);
    }
  });
}

Future<void> _checkExactAlarmPermission() async {
  if (await AwesomeNotifications().isNotificationAllowed() == false) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  
  
  if (await DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt) >= 31) {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      );
      await intent.launch();
    }
  }
}

//NOT SURE IF WE USE THIS METHOD
Future<void> _requestExactAlarmPermission() async {
  // prefs = await SharedPreferences.getInstance();
  bool isAlarmPermissionGranted =
      prefs.getBool('alarmPermissionGranted') ?? false;

  if (!isAlarmPermissionGranted && (await getAndroidSdkVersion()) >= 31) {
    // ✅ Use navigatorKey to get context safely
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: const Text("Enable Alarm Permissions"),
            content: const Text(
                "This app needs permission to schedule exact alarms. Please allow it in settings."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // ✅ User can cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  const intent = AndroidIntent(
                    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
                    flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                  );
                  await intent.launch();
                  await prefs.setBool('alarmPermissionGranted', true);
                },
                child: const Text("Proceed"),
              ),
            ],
          );
        },
      );
    }
  }
}

Future<int> getAndroidSdkVersion() async {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  return androidInfo.version.sdkInt;
}

class MyApp extends StatelessWidget {
  
    final bool showIntro;
  const MyApp({super.key, required this.showIntro});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      if (!kIsWeb) {
      return AppLifecycleManager(
        child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'When Did You Last?',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: FutureBuilder<bool>(
        future: _loadEverything(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return kIsWeb ? const MyHomePage() : showIntro ? const IntroPermissionsScreen() : const MyHomePage(); // Set HomeScreen as the main screen
          } else {
            return const LoadingScreen(); // Show spinner while waiting
          }        
      }
        )
      )
      );
    }
  
  else {
    return MaterialApp(navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'When Did You Last?',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: FutureBuilder<bool>(
        future: _loadEverything(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyHomePage();
          } else {
            return const LoadingScreen(); // Show spinner while waiting
          }
        }
        )
        
        
        
        
        
       // const MyHomePage(), // Set HomeScreen as the main screen
    );
  }
  });
  }
  
}
