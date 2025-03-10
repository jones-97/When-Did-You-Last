import 'package:flutter/material.dart';
import 'tasks_list.dart';
import 'date_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});



  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;

  // void _incrementCounter() {
  //   setState(() {
  //     _counter++;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff3ae882),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "When Did You Last...?",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 18, // Increased font size
            color: Color(0xff000000),
          ),
        ),
        actions:  [
         // Icon(Icons.menu, color: Color(0xff212435), size: 24),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xff212435), size: 24),
            onSelected: (value) {
              if (value == 'Task View') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TasksList()),
                );
              }
            },
            itemBuilder: (context) => [
             const PopupMenuItem(value: 'Task View', child: Text('Task View')),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: const Alignment(0.0, -0.3),
        child: Container(
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.all(0),
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0x1f000000),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
          ),
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime(DateTime.now().year),
            lastDate: DateTime(2050),
            onDateChanged: (date) {
              Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DateView(selectedDate: date)),
);
            },
          ),
        ),
      ),
    );
  }
}