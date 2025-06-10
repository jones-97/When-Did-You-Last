import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:when_did_you_last/Models/task.dart';
import 'package:when_did_you_last/Util/database_helper.dart';


class TaskBackup {

  Future<void> exportTasks2(List<Task> tasks) async {
    //Not in use
  final jsonList = tasks.map((t) => t.toJson()).toList();
  final jsonString = jsonEncode(jsonList);

  final directory = await getExternalStorageDirectory(); // Consider app-specific or downloads
  final file = File('${directory!.path}/task_backup.myreminders');

  await file.writeAsString(jsonString);
  debugPrint('TASK-BACKUP::: Backup saved to ${file.path}');
}

  Future<void> exportTasks() async {

  List<Task> tasks = await DatabaseHelper().getTasks();
  final jsonList = tasks.map((t) => t.toJson()).toList();
  final jsonString = jsonEncode(jsonList);

  final directory = await getExternalStorageDirectory(); // Consider app-specific or downloads
  final file = File('${directory!.path}/task_backup.myreminders');

  await file.writeAsString(jsonString);
  debugPrint('TASK-BACKUP::: Backup saved to ${file.path}');
}

Future<void> importTasks() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['myreminders'], // restrict to your file extension
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);

    final tasks = jsonList.map((json) => Task.fromJson(json)).toList();

    for (final task in tasks) {
      await DatabaseHelper().insertTask(task); // Or your own insert logic
    }

    debugPrint("TASK-BACKUP::: Import complete: ${tasks.length} tasks added.");
  } else {
    debugPrint("TASK-BACKUP::: No file selected.");
  }
}

}