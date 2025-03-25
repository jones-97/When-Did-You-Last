import 'package:flutter/material.dart';
import 'Util/database_helper.dart';
import 'Models/task.dart';
import 'new_task.dart';
import 'package:intl/intl.dart';

class DateView extends StatefulWidget {
  final DateTime selectedDate;
  

  DateView({super.key, required this.selectedDate});

  @override
  _DateViewState createState() => _DateViewState();
}

class _DateViewState extends State<DateView> {
  final dbHelper = DatabaseHelper();
  
  List<Task> _tasks = [];
  Map<int, bool> _taskCompletionStatus = {}; // Track task completion

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // @override
  // void dispose() {
  //   Navigator.pop(context, true);
  //   super.dispose();
  // }

  Future<void> _loadTasks() async {
    final tasks = await dbHelper.getTasks();
    for (var task in tasks) {
      task.completedDates = await dbHelper.getTaskCompletionDates(task.id!);
    }
    setState(() {
      _tasks = tasks;
      _taskCompletionStatus = {
        for (var task in _tasks)
          task.id!: task.completedDates.contains(widget.selectedDate.toIso8601String())
      };
    });
  }

  Future<void> _toggleTaskCompletion(Task task, bool isDone) async {
    if (isDone) {
      await dbHelper.markTaskDone(task.id!, widget.selectedDate.toIso8601String());
    } else {
      await dbHelper.unmarkTaskDone(task.id!, widget.selectedDate.toIso8601String());
    }
    _loadTasks();

    // Refresh home page to highlight completed dates
   // Navigator.pop(context, true);  // Return "true" to signal a refresh
  }

  String viewingDate(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    return formattedDate;
  }
  

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(title: Text("Tasks on ${viewingDate(widget.selectedDate)}"),
      leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true);
            },
            ),
      ),
      body: Column(
        children: [
          const Padding(
            padding:  EdgeInsets.fromLTRB(0, 10, 0, 0),
            child:  Text("Check a Task as Done today",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color.fromARGB(1, 88, 166, 245)),)
            
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return CheckboxListTile(
                  title: Text(task.name),
                  value: _taskCompletionStatus[task.id] ?? false,
                  onChanged: (bool? value) {
                    _toggleTaskCompletion(task, value ?? false);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: MaterialButton(
               shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Color(0xff808080), width: 1),
              ),
            color: const Color(0xff3ae882),
            child: const Text("New Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
            onPressed:  () => 
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  NewTask()),
          )
          )
          ),
        ],
      ),
      )
    );
  }
}