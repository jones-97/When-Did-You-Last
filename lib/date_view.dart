import 'package:flutter/material.dart';
import 'Data/database_helper.dart';
import 'Models/task.dart';

class DateView extends StatefulWidget {
  final DateTime selectedDate;

  const DateView({super.key, required this.selectedDate});

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
    Navigator.pop(context, true);  // Return "true" to signal a refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tasks on ${widget.selectedDate.toLocal()}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: DropdownButton<String>(
              items: _tasks.map((task) {
                return DropdownMenuItem<String>(
                  value: task.name,
                  child: Text(task.name),
                );
              }).toList(),
              onChanged: (value) {},
              isExpanded: true,
              hint: Text("Select a task"),
            ),
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
        ],
      ),
    );
  }
}