import 'package:flutter/material.dart';
// import 'Data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:io';
import 'home_page.dart'; // Import the new home.dart file

void main() async {
  try {

  //   if (Platform.isWindows || Platform.isLinux) {
  //   // Initialize FFI
  //   sqfliteFfiInit();
  // }

  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is fully initialized

  // Initialize the database before running the app
  // final dbHelper = DatabaseHelper();
  // await dbHelper.database;


  if (kIsWeb) {
  // running on the web!
    databaseFactory = databaseFactoryFfiWeb;
} else {
  // NOT running on the web! You can check for additional platforms here.
    databaseFactory = databaseFactoryFfi;
}
 
  runApp(const MyApp());}
  catch (e) {
    print("Problem initializing the whole app:  $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'When Did You Last?',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(), // Set HomeScreen as the main screen
    );
  }
}
