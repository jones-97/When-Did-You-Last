import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:when_did_you_last/home_page.dart';
import 'package:when_did_you_last/new_task.dart';
import 'Util/database_helper.dart';
import 'Models/task.dart';
import 'settings.dart';
import 'edit_task.dart';

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
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final twoDaysLaterStart = todayStart.add(Duration(days: 2));

    List<Task> tasksDueToday = _tasks.where((task) {
      if (task.notifyDate == null) return false;
      final taskDate = DateTime.parse(task.notifyDate!);
      return (taskDate.isAfter(todayStart) ||
              taskDate.isAtSameMomentAs(todayStart)) &&
          taskDate.isBefore(todayStart.add(Duration(days: 1)));
    }).toList();

    List<Task> tasksDueInTwoDays = _tasks.where((task) {
      if (task.notifyDate == null) return false;
      final taskDate = DateTime.parse(task.notifyDate!);
      return (taskDate.isAfter(twoDaysLaterStart) ||
              taskDate.isAtSameMomentAs(twoDaysLaterStart)) &&
          taskDate.isBefore(twoDaysLaterStart.add(Duration(days: 1)));
    }).toList();

    List<Task> otherTasks = _tasks
        .where((task) =>
            task.notifyDate != now && task.notifyDate != twoDaysLaterStart)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff947448),
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
              if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Home View', child: Text('Home View')),
              const PopupMenuItem(value: 'Settings', child: Text('Settings'))
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
          child: Column(
            children: [

          _buildSwipableTaskSection("Tasks Due Today", tasksDueToday),
          _buildSwipableTaskSection("Tasks Due in Two Days", tasksDueInTwoDays),
          const SizedBox(height: 20), // Adds spacing before task list
          _buildTaskSection("Tasks List", otherTasks),
            ]
          )
        
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3ae882),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewTask()),
          ).then((_) => _loadTasks());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
    
  }

  Widget _buildSwipableTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SizedBox(
          height: 200,
          child: tasks.isEmpty
              ? const Center(child: Text("No tasks available."))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 250,
                      child: Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(tasks[index].name),
                          subtitle: Text("Due: ${tasks[index].notifyDate}"),
                          onTap: () async {
                            bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditTask(currentTask: tasks[index]),
                              ),
                            );
                            if (updated == true) {
                              _loadTasks();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        )
      ],
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No tasks available."),
          )
        else
          Column(
            children: tasks.map((task) => _buildTaskTile(task)).toList(),
          ),
      ],
    );
  }

  Widget _buildTaskTile(Task task) {
    return ListTile(
      tileColor: const Color(0x1f000000),
      title: Text(task.name),
      subtitle: Text(
        task.notifyDate != null
            ? "Scheduled: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(task.notifyDate!))}"
            : task.notifyHours != null
                ? "Repeats every ${task.notifyHours} hours"
                : task.notifyDays != null
                    ? "Repeats every ${task.notifyDays} days"
                    : "No reminders",
      ),
      onTap: () async {
        bool? updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTask(currentTask: task),
          ),
        );
        if (updated == true) {
          _loadTasks();
        }
      },
    );
    
  }
}
