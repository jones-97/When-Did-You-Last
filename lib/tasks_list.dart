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
  List<Task> tasksDueToday = [];
  List<Task> tasksDueInTwoDays = [];
  List<Task> otherTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

/*
  Future<void> _loadTasks() async {
    try {
      final tasks = await dbHelper.getTasks();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final twoDaysLaterStart = todayStart.add(const Duration(days: 2));

      setState(() {
        _tasks = tasks;
        
        tasksDueToday = _tasks.where((task) {
          if (task.notificationTime == null) return false;

          final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
          return taskDate.isAfter(todayStart) && 
                 taskDate.isBefore(todayStart.add(const Duration(days: 1)));
        }).toList();

        tasksDueInTwoDays = _tasks.where((task) {
          if (task.notificationTime == null) return false;

          final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
          return taskDate.isAfter(twoDaysLaterStart) && 
                 taskDate.isBefore(twoDaysLaterStart.add(const Duration(days: 1)));
        }).toList();

        otherTasks = _tasks.where((task) {
          if (task.notificationTime == null) return true;
          final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
          return !taskDate.isAfter(todayStart) || 
                 taskDate.isAfter(twoDaysLaterStart.add(const Duration(days: 1)));
        }).toList();
      });
    } catch (e) {
      log("Error loading tasks: $e");
    }
  }
*/
    Future<void> _loadTasks() async {
    try {
      final tasks = await dbHelper.getTasks();
      _categorizeTasks(tasks);
    } catch (e) {
      log("Error loading tasks: $e");
    }
  }

  void _categorizeTasks(List<Task> tasks) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final tomorrowEnd = todayEnd.add(const Duration(days: 1));

    setState(() {
      _tasks = tasks;
      
      tasksDueToday = _tasks.where((task) {
        if (task.notificationTime == null) return false;
        final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
        return taskDate.isAfter(now) && taskDate.isBefore(todayEnd);
      }).toList();

      tasksDueInTwoDays = _tasks.where((task) {
        if (task.notificationTime == null) return false;
        final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
        return taskDate.isAfter(todayEnd) && taskDate.isBefore(tomorrowEnd);
      }).toList();

      otherTasks = _tasks.where((task) {
        if (task.notificationTime == null) return true;
        final taskDate = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
        return taskDate.isAfter(tomorrowEnd) || taskDate.isBefore(now);
      }).toList();
    });
  }

  String _formatTaskTime(Task task) {
    if (task.notificationTime == null) return "No due date";
    final date = DateTime.fromMillisecondsSinceEpoch(task.notificationTime!);
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff947448),
        title: const Text(
          "Tasks View",
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xff000000)
          )
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xff212435), size: 24),
            onSelected: (value) {
              if (value == 'Home View') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage()));
              } else if (value == 'Settings') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Home View', child: Text('Home View')),
              const PopupMenuItem(value: 'Settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskSection("Tasks Due Today", tasksDueToday),
            _buildTaskSection("Tasks Due In Two Days", tasksDueInTwoDays),
            const SizedBox(height: 20),
            _buildTaskSection("Other Tasks", otherTasks),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff3ae882),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewTask()))
              .then((_) => _loadTasks());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("No tasks in this category"),
          )
        else
          ...tasks.map((task) => _buildTaskCard(task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        title: Text(task.name),
        subtitle: Text(
          task.notificationTime != null 
              ? "Due: ${_formatDateTime(task.notificationTime!)}"
              : "No due date",
        ),
        trailing: IconButton(
          icon: Icon(
            task.notificationsPaused ? Icons.notifications_off : Icons.notifications_active,
            color: task.notificationsPaused ? Colors.grey : Colors.blue,
          ),
          onPressed: () => _toggleNotifications(task),
        ),
        onTap: () async {
          bool? updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditTask(task: task)),
          );
          if (updated == true) _loadTasks();
        },
      ),
    );
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  Future<void> _toggleNotifications(Task task) async {
    try {
      await dbHelper.updateTask(
        Task(
          id: task.id,
          name: task.name,
          taskType: task.taskType,
          repeatType: task.repeatType,
          customInterval: task.customInterval,
          notificationTime: task.notificationTime,
          notificationsPaused: !task.notificationsPaused,
        ),
      );
      _loadTasks();
    } catch (e) {
      log("Error toggling notifications: $e");
    }
  }
}