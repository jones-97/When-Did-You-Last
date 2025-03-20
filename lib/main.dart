import 'package:flutter/material.dart';
// import 'Data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:when_did_you_last/settings.dart';
import 'package:provider/provider.dart';
import 'Util/theme_provider.dart';


// import 'dart:io';
import 'home_page.dart'; // Import the new home.dart file
late SharedPreferences prefs;

void main() async {
  try {

  //   if (Platform.isWindows || Platform.isLinux) {
  //   // Initialize FFI
  //   sqfliteFfiInit();
  // }

  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is fully initialized
  // prefs = await SharedPreferences.getInstance();
  //  bool isDarkMode = prefs.getBool('darkMode') ?? false;

  

  // Initialize the database before running the app
  // final dbHelper = DatabaseHelper();
  // await dbHelper.database;


  if (kIsWeb) {
  // running on the web!
    databaseFactory = databaseFactoryFfiWeb;
    //Ensures IndexedDB is properly used because of persistence issues (remembering data) on the web

} else {
  // NOT running on the web! You can check for additional platforms here.
    databaseFactory = databaseFactoryFfi;
}
 
  runApp(
    ChangeNotifierProvider(create: (context) => ThemeProvider(),
    child: const MyApp()  
    )
  );
  }
  catch (e) {
    debugPrint("Problem initializing the whole app:  $e");
  }
}

class MyApp extends StatelessWidget {
  

  const MyApp({super.key});

  /*

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', value);

    setState(() {
      _isDarkMode = value;
    });
  }
*/

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'When Did You Last?',
      theme: ThemeData.light(), 
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MyHomePage(), // Set HomeScreen as the main screen
    );
      }
    );
  }
}
