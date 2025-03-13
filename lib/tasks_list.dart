///File download from FlutterViz- Drag and drop a tools. For more details visit https://flutterviz.io/
library;

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:when_did_you_last/home_page.dart';
import 'package:when_did_you_last/new_task.dart';
import 'Data/database_helper.dart';
import 'Models/task.dart';



class TasksList extends StatefulWidget {
  @override
  _TasksListState createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  final dbHelper = DatabaseHelper();
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await dbHelper.getTasks();
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      log("Error loading tasks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff947448),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "Tasks View",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Color(0xff000000),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xff212435), size: 24),
            onSelected: (value) {
              if (value == 'Home View') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Home View', child: Text('Home View')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          //The List of Tasks
          Expanded( // Wrap ListView.builder in Expanded
            child: ListView.builder(
              
              itemCount: _tasks.isEmpty ? 1 : _tasks.length,
              itemBuilder: (context, index) {
                if (_tasks.isEmpty) {
                return const ListTile(
                  title: Center(
                    child: Text(
                      "Empty; Tasks will Appear Here",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
                final task = _tasks[index];
                return ListTile(
                  minTileHeight: 20.0,
                  tileColor: const Color(0x1f000000),
                  title: Text(task.name),
                  subtitle: Text(
                    task.notifyDate != null
                        ? "Scheduled: ${task.notifyDate}"
                        : task.notifyHours != null
                            ? "Repeats every ${task.notifyHours} hours"
                            : task.notifyDays != null
                                ? "Repeats every ${task.notifyDays} days"
                                : "No reminders",
                  ),
                );
              },
            ),
          ),
          //Ensuring the button is always visible

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NewTask()),
                ).then((_) => _loadTasks());
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff3ae882),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Color(0xff808080), width: 1),
              ),
              ),
              child: const Padding(
              padding: EdgeInsets.all(16),
              // textColor: const Color.fromARGB(255, 255, 255, 255),
              // height: 40,
              // minWidth: 140,
              child: Text(
                "NEW TASK",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontStyle: FontStyle.normal,
                ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

           

            
            
      
      
      
      
      
      
      
      
      
      
      
      
//       ListView(
//         scrollDirection: Axis.vertical,
//         padding: const EdgeInsets.all(0),
//         shrinkWrap: false,
//         physics: const ScrollPhysics(),
//         children: [

//           const ListTile(
//             tileColor: Color(0x1f000000),
//             title: Text(
//               "Task Name",
//               style: TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontStyle: FontStyle.normal,
//                 fontSize: 14,
//                 color: Color(0xff000000),
//               ),
//               textAlign: TextAlign.start,
//             ),
//             subtitle: Text(
//               "Repeats/Does Not Repeat",
//               style: TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontStyle: FontStyle.normal,
//                 fontSize: 14,
//                 color: Color(0xff000000),
//               ),
//               textAlign: TextAlign.start,
//             ),
//             dense: false,
//             contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//             selected: false,
//             selectedTileColor: Color(0x42000000),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.zero,
//               side: BorderSide(color: Color(0x4d9e9e9e), width: 1),
//             ),
//           ),


//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: MaterialButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => NewTask())
//                 );
//               },
//               color: const Color(0xff3ae882),
//               elevation: 0,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.zero,
//                 side: BorderSide(color: Color(0xff808080), width: 1),
//               ),
//               padding: const EdgeInsets.all(16),
              
//               textColor: const Color.fromARGB(255, 255, 255, 255),
               
//               height: 40,
//               minWidth: 140,
//               child: const Text(
//                 "NEW TASK",
//                 style:  TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w400,
//                   fontStyle: FontStyle.normal,
//                 ),
//               ),
//             ),
//           ),
//       