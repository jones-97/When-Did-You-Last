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
  bool _loading = false;

  final dbHelper = DatabaseHelper();
  List<Task> _trackerTasks = [];
  List<Task> _reminderTasksCompleted = [];
  Map<int, List<String>> _taskCompletionDates = {};
  Map<int, bool> _taskCompletionStatus = {};// Track task completion status

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

/*
  Future<void> _loadTasks() async {
    final tasks = await dbHelper.getTasks();
    final filteredTasks = tasks.where((task) {
      return task.taskType == "No Alert/Tracker";
    }).toList();

    // Initialize completion dates for each task
    final completionDatesMap = <int, List<String>>{};
    for (var task in filteredTasks) {
      completionDatesMap[task.id!] =
          await dbHelper.getTaskCompletionDates(task.id!);
    }

    setState(() {
      _loading = true;
      _tasks = filteredTasks;
      _taskCompletionDates = completionDatesMap;
      _taskCompletionStatus = {
        for (var task in _tasks)
          task.id!: _taskCompletionDates[task.id!]?.contains(
                widget.selectedDate.toIso8601String(),
              ) ??
              false
      };
    });
  }
*/


  Future<void> _loadTasks() async {
    final allTasks = await dbHelper.getTasks();
    final todayIsoString = widget.selectedDate.toIso8601String();

    final trackerTasks = <Task>[];
    final reminderTasks = <Task>[];

    final completionDatesMap = <int, List<String>>{};

    for (var task in allTasks) {
      final completionDates = await dbHelper.getTaskCompletionDates(task.id!);
      completionDatesMap[task.id!] = completionDates;

      if (task.taskType == "No Alert/Tracker") {
        trackerTasks.add(task);
      } else if ((task.taskType == "One-Time" || task.taskType == "Repetitive") &&
          completionDates.contains(todayIsoString)) {
             reminderTasks.add(task);
      }
    }

    setState(() {
      _trackerTasks = trackerTasks;
      _reminderTasksCompleted = reminderTasks;
      _taskCompletionDates = completionDatesMap;
      _taskCompletionStatus = {
        for (var task in _trackerTasks)
          task.id!: _taskCompletionDates[task.id!]?.contains(todayIsoString) ?? false
      };
    });
  }



  Future<void> _toggleTaskCompletion(Task task, bool isDone) async {
    final dateString = widget.selectedDate.toIso8601String();

    setState(() {
      _taskCompletionStatus[task.id!] = isDone;
      if (isDone) {
        _taskCompletionDates[task.id!] ??= [];
        _taskCompletionDates[task.id!]!.add(dateString);
      } else {
        _taskCompletionDates[task.id!]?.remove(dateString);
      }
    });

    // Update database
    if (isDone) {
      await dbHelper.markTaskDone(task.id!, dateString);
    } else {
      await dbHelper.unmarkTaskDone(task.id!, dateString);
    }
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
          appBar: AppBar(
            backgroundColor:const Color.fromARGB(255, 231, 189, 130),
            title: Text("Tasks on ${viewingDate(widget.selectedDate)}"),
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
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Text(
                    "Check a Task as Done today",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color.fromARGB(1, 88, 166, 245)),
                  )
                  ),

              Expanded(
                child: ListView(
                  children: [
                  // TRACKER TASKS
                  ..._trackerTasks.map((task) => CheckboxListTile(
                        title: Text(task.name),
                        value: _taskCompletionStatus[task.id] ?? false,
                        onChanged: (bool? value) {
                          _toggleTaskCompletion(task, value ?? false);
                        },
                      )),

                  // REMINDER TASKS SECTION
                   if (_reminderTasksCompleted.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Reminder Tasks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._reminderTasksCompleted.map((task) => ListTile(
                          title: Text(task.name),
                          subtitle: task.details != null ? Text(task.details!) : null,
                        )),
                  ],


                  // itemCount: _tasks.length,
                  // itemBuilder: (context, index) {
                  //   final task = _tasks[index];
                  //   return CheckboxListTile(
                  //     title: Text(task.name),
                  //     value: _taskCompletionStatus[task.id] ?? false,
                  //     onChanged: (bool? value) {
                  //       _toggleTaskCompletion(task, value ?? false);
                  //     },
                  //   );
                  // },
                  ],



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
                      child: const Text("New Task",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400)),
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NewTask()),
                          ).then((_) {
                            _loadTasks(); // Refresh tasks after returning
                            setState(() {}); // Ensure UI updates
                          }))),
            ],
          ),
        ));
  }
}
