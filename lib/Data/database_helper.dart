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
        version: 1,
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
          print("Database created successfully"); // Log database creation
        },
      );
    } catch (e) {
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
}