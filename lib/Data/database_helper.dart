import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:when_did_you_last/Models/task.dart';

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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'tasks.db');

      print("Database path: $path"); // Log the database path

      return await openDatabase(
        path,
        version: 2, //Changing version to force migration
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              completed INTEGER DEFAULT 0,
              notify_hours INTEGER,
              notify_days INTEGER,
              notify_date TEXT
            )
          ''');

          db.execute('''
        CREATE TABLE task_completion (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          completed_date TEXT NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        )
      ''');
      print("Database creation successfult");
    },
    onUpgrade: (db, oldVersion, newVersion) {
      if (oldVersion < 2) {
        db.execute('''
          CREATE TABLE task_completion (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            completed_date TEXT NOT NULL,
            FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
          )
        ''');
      }
    },
  );
}
        catch (e) {
      print("Database initialization error: $e");
      rethrow;
    }
  }

  // Insert a Task
  Future<int> insertTask(Task task) async {
    try {
      final db = await database;
      return await db.insert('tasks', task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error inserting task: $e");
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
      print("Error retrieving tasks: $e");
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
      print("Error updating task: $e");
      rethrow;
    }
  }

  // Delete a Task
  Future<int> deleteTask(int id) async {
    try {
      final db = await database;
      return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print("Error deleting task: $e");
      rethrow;
    }
  }

// HANDLING TASK COMPLETION DATES

//mark a task done
Future<void> markTaskDone(int taskId, String date) async {
  try{
  final db = await database;
  await db.insert(
    'task_completion',
    {'task_id': taskId, 'completed_date': date},
    conflictAlgorithm: ConflictAlgorithm.ignore, // Prevent duplicates
  );
  } catch (e) {
    print("Error marking a task as done: $e");
  }
}

// Remove a completion date
Future<void> unmarkTaskDone(int taskId, String date) async {
  try{
  final db = await database;
  await db.delete(
    'task_completion',
    where: 'task_id = ? AND completed_date = ?',
    whereArgs: [taskId, date],
  );
  } catch (e) {
    print("Error unmarking or making a task NOT DONE: $e");
  }
}

// Get completion dates for a task
Future<List<String>> getTaskCompletionDates(int taskId) async {
  try{
  final db = await database;
  final List<Map<String, dynamic>> results = await db.query(
    'task_completion',
    where: 'task_id = ?',
    whereArgs: [taskId],
  );
  return results.map((row) => row['completed_date'].toString()).toList();
  } catch (e) {
    print("Error getting a task's completion dates: $e");
    return [];
  }
}




}