import 'package:flutter/material.dart';
import 'home_page.dart'; // Import the new home.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'When Did You Last?',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(), // Set HomeScreen as the main screen
    );
  }
}
