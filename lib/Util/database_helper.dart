import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:when_did_you_last/Models/task.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {

  //  databaseFactory = kIsWeb ? databaseFactoryFfiWeb : databaseFactoryFfi; // ✅ Use correct factory
  if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb; // ✅ Use IndexedDB for Web
    }

    //WE WILL HAVE TO RENAME SOME FIELDS HERE TO REDUCE CONFUSION.

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tasks.db');

      debugPrint("Database path: $path"); // Log the database path

      return await openDatabase(
        path,
        version: 1, //Can change the version to force migration
        onCreate: (db, version) async {
          await db.execute('''
  CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    details TEXT,
  
    task_type TEXT NOT NULL,
    duration_type TEXT,
    auto_repeat INTEGER DEFAULT 0,
    custom_interval INTEGER DEFAULT NULL, 
    notification_time INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    notifications_enabled INTEGER DEFAULT 1
  )
''');


          db.execute('''
        CREATE TABLE completed_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          completed_date TEXT NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        )
      ''');

      
          db.execute('''
        CREATE TABLE running_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          start_time TEXT,
          elapsed_time INTEGER,
          paused INTEGER DEFAULT 0,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        )
      ''');
      debugPrint("Database creation successfult");
    },
   
  );
}
        catch (e) {
      debugPrint("Database initialization error: $e");
      rethrow;
    }
  }

  // Insert a Task
  Future<int> insertTask(Task task) async {
    try {
      debugPrint("Task inserted successfully!");
      final db = await database;
      return await db.insert('tasks', task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
          
          
    } catch (e) {
      debugPrint("Error inserting task: $e");
      rethrow;
    }
    
  }

  // Retrieve All Tasks
  Future<List<Task>> getTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('tasks');
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error retrieving tasks: $e");
      rethrow;
    }
  }

  // Update a Task
  Future<int> updateTask(Task task) async {
    try {
      final db = await database;
      return await db.update('tasks', task.toMap(),
          where: 'id = ?', whereArgs: [task.id]);
    } catch (e) {
      debugPrint("Error updating task: $e");
      rethrow;
    }
  }

  // Delete a Task
  Future<int> deleteTask(int id) async {
    try {
      final db = await database;
      return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint("Error deleting task: $e");
      rethrow;
    }
  }

// HANDLING TASK COMPLETION DATES

//pause a task NOTIFICATIONS
Future<void> pauseTask(int taskId) async {
  try {
      final db = await database;

    await db.rawUpdate('''
    UPDATE tasks 
    SET notification_paused = 1,
    WHERE _id = ?}
    ''',
    [taskId]);
    } catch (e) {
      debugPrint("Error pausing task: $e");
      rethrow;
    }
}

//restart a task
Future<void> resumeTask (int taskId) async {

  try {
      final db = await database;

    await db.rawUpdate('''
    UPDATE tasks 
    SET notification_paused = 0,
    WHERE _id = ?}
    ''',
    [taskId]);
    } catch (e) {
      debugPrint("Error resuming task: $e");
      rethrow;
    }
}

//mark a task done
Future<void> markTaskDone(int taskId, String date) async {
  try{
  final db = await database;
  await db.insert(
    'completed_tasks',
    {'task_id': taskId, 'completed_date': date},
    conflictAlgorithm: ConflictAlgorithm.ignore, // Prevent duplicates
  );
  } catch (e) {
    debugPrint("Error marking a task as done: $e");
  }
}

// Remove a completion date
Future<void> unmarkTaskDone(int taskId, String date) async {
  try{
  final db = await database;
  await db.delete(
    'completed_tasks',
    where: 'task_id = ? AND completed_date = ?',
    whereArgs: [taskId, date],
  );
  } catch (e) {
    debugPrint("Error unmarking or making a task NOT DONE: $e");
  }
}

Future<void> removeFromCompletionDates(int taskId) async {
  try {
    final db = await database;
    await db.delete('completed_tasks',
    where: 'task_id = ?',
    whereArgs: [taskId]);
    debugPrint("Successfully removed task from the completion table.");
  } catch (e) {
    debugPrint("Error removing task from the completed tasks table: $e");
  }
}

// Get completion dates for a task
Future<List<String>> getTaskCompletionDates(int taskId) async {
  try{
  final db = await database;
  final List<Map<String, dynamic>> results = await db.query(
    'completed_tasks',
    where: 'task_id = ?',
    whereArgs: [taskId],
  );
  return results.map((row) => row['completed_date'].toString()).toList();
  } catch (e) {
    debugPrint("Error getting a task's completion dates: $e");
    return [];
  }
}


Future<Task?> getTaskById(int taskId) async {
  final db = await database;
  final List<Map<String, dynamic>> maps =
      await db.query('tasks', where: 'id = ?', whereArgs: [taskId]);

  if (maps.isNotEmpty) {
    return Task.fromMap(maps.first);
  }
  return null;
}

Future<List<Task>> getTasksDueSoon() async {
  final db = await database;
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1)).toIso8601String().split('T')[0];
  final dayAfterTomorrow = now.add(const Duration(days: 2)).toIso8601String().split('T')[0];

  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * FROM tasks
    WHERE notification_time IN (?, ?)
  ''', [tomorrow, dayAfterTomorrow]);

  return maps.map((map) => Task.fromMap(map)).toList();
}






}