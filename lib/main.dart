import 'package:flutter/material.dart';
// import 'Data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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

  databaseFactory = databaseFactoryFfiWeb;
 
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
