import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Models/task.dart';
import 'Util/database_helper.dart';
import 'Util/notification_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditTask extends StatefulWidget {
  final Task task;

  const EditTask({required this.task});

  @override
  _EditTaskState createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  final dbHelper = DatabaseHelper();

  late TextEditingController _nameController;
  late TextEditingController _detailsController;
  late TextEditingController _hoursController;
  late TextEditingController _daysController;

  String? _selectedTaskType = "No Alert/Tracker";
  String? _selectedDurationType;
  bool _showDetails = false;
  bool _autoRepeat = false;
  DateTime? _selectedDate;
  String? selectedDateString;
  int? _notificationTime;
  bool _notificationsEnabled = false;
  // Duration? _timeOffset;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _detailsController = TextEditingController();
    _hoursController = TextEditingController();
    _daysController = TextEditingController();

    _nameController.text = widget.task.name;
    _selectedTaskType = widget.task.taskType;

    //BELOW LINE IS CONFUSING. WE ARE USING "Notifications Enabled".
    //Notificationspaused is false when a task is running. So we have to negate it to "TRUE"
    //when a task is running. Hope this made sense.

    _notificationsEnabled = widget.task.notificationsEnabled;
    _detailsController.text = widget.task.details ?? '';
    _autoRepeat = widget.task.autoRepeat;

    _initializeNotificationSettings();
  }

  void _initializeNotificationSettings() {
    _selectedTaskType = widget.task.taskType;
    _notificationsEnabled = widget.task.notificationsEnabled;
    // Set the radio button based on repeatType
    _selectedDurationType =
        widget.task.durationType == 'None' ? null : widget.task.durationType;
    // "No Alert/Tracker";
    //                 "One-Time";
    //                 "Repetitive";

    if (widget.task.details != null) {
      _showDetails = true;
    }

    if (widget.task.customInterval != null) {
      // For tasks with stored custom interval
      if (widget.task.durationType == 'Days') {
        _daysController.text = widget.task.customInterval.toString();
      } else if (widget.task.durationType == 'Hours') {
        _hoursController.text = widget.task.customInterval.toString();
      }
    } else if (widget.task.notificationTime != null) {
      // Fallback for legacy tasks without custom_interval

      final taskTime =
          DateTime.fromMillisecondsSinceEpoch(widget.task.notificationTime!);

      if (widget.task.durationType == 'Days') {
        // Calculate approximate days (rounded to nearest whole number)
        double days = (widget.task.notificationTime! -
                DateTime.now().millisecondsSinceEpoch) /
            (1000 * 60 * 60 * 24);
        _daysController.text = days.round().toString();
      } else if (widget.task.durationType == 'Hours') {
        double hours = (widget.task.notificationTime! -
                DateTime.now().millisecondsSinceEpoch) /
            (1000 * 60 * 60);
        _hoursController.text = hours.round().toString();
      } else if (widget.task.durationType == 'Specific') {
        _selectedDate = taskTime;
        selectedDateString =
            DateFormat('MMM dd, yyyy - hh:mm a').format(taskTime);
      }
    }
  }
/*
    if (widget.task.notificationTime != null) {
      final now = DateTime.now();
      final taskTime = DateTime.fromMillisecondsSinceEpoch(widget.task.notificationTime!);
      _timeOffset = taskTime.difference(now);

      // Pre-fill values based on repeatType
      switch (widget.task.repeatType) {
        case 'hours':
        _hoursController.text = widget.task.customInterval.toString();
          break;
        case 'days':
          _daysController.text = widget.task.customInterval.toString();
          break;
        case 'specific':
          _selectedDate = taskTime;
          selectedDateString = DateFormat('MMM dd, yyyy - hh:mm a').format(taskTime);
          break;
      }
    }
  */

  Future<void> _markTaskAsCompleteForTesting() async {
    try {
      final today = DateTime.now();
      final formattedDate = today.toIso8601String();

      await DatabaseHelper().markTaskDone(widget.task.id!, formattedDate);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        elevation: 6,
        content: const Text("Task marked as complete for testing!"),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        duration: const Duration(seconds: 3),
      ));

      
    } catch (e) {
      debugPrint("Error marking task as complete: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mark task as complete")),
      );
    }
  }

  Future<bool> isTaskActive(Task task) async {
    final db = DatabaseHelper();

    if (task.taskType == "No Alert/Tracker") return false;

    if (task.taskType == "One-Time") {
      List<String> completions = await db.getTaskCompletionDates(task.id!);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      return !completions.any((date) => date.startsWith(today));
    }

    if (task.taskType == "Repetitive") {
      return task.notificationsEnabled == true;
    }

    return true;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          selectedDateString =
              DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate!);
        });
      }
    }
  }

  void calculateDateTime() {
    if (_selectedDate != null) {
      _notificationTime = _selectedDate!.millisecondsSinceEpoch;
      return;
    }

    if (_selectedDurationType == 'Hours' && _hoursController.text.isNotEmpty) {
      int hours = int.tryParse(_hoursController.text) ?? 0;
      if (hours > 0) {
        _notificationTime =
            DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
      }
    } else if (_selectedDurationType == 'Days' &&
        _daysController.text.isNotEmpty) {
      int days = int.tryParse(_daysController.text) ?? 0;
      if (days > 0) {
        _notificationTime =
            DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
      }
    }
  }

  Future<void> _updateTask() async {

    
    if (_selectedTaskType != "No Alert/Tracker") {
      
      bool hasNoDays = _daysController.text.trim().isEmpty;
      bool hasNoHours = _hoursController.text.trim().isEmpty;
      bool hasNoDate = _selectedDate == null;

      if (hasNoDays && hasNoHours && hasNoDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Please provide a reminder value (hours, days, or date/time).")),
        );
        return; // Prevent saving
      }
    }

    try {
      calculateDateTime();

      // Determine custom_interval value
      int? customInterval;
      if (_selectedDurationType == 'Hours' &&
          _hoursController.text.isNotEmpty) {
        customInterval = int.tryParse(_hoursController.text);
      } else if (_selectedDurationType == 'Days' &&
          _daysController.text.isNotEmpty) {
        customInterval = int.tryParse(_daysController.text);
      }

      final updatedTask = Task(
        id: widget.task.id,
        name: _nameController.text,
        details: _showDetails ? _detailsController.text : null,
        taskType: _selectedTaskType!,
        durationType: _selectedDurationType ?? "None",
        autoRepeat: _autoRepeat,
        notificationTime: _notificationTime,
        notificationsEnabled: _notificationsEnabled,
        customInterval: customInterval ??
            0, //stores original interval value eg 1 hour, 2 days
      );
      if (updatedTask.taskType != "No Alert/Tracker") {
        debugPrint("Updating task in completion_table. Check message below...");

        await DatabaseHelper().removeFromCompletionDates(updatedTask.id!);
      }
      final result = await DatabaseHelper().updateTask(updatedTask);

      //SCHEDULE NOTIFICATION
      if (!kIsWeb) {
        if (updatedTask.taskType == "No Alert/Tracker") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            elevation: 6,
            content: const Text("Task Updated Successfully!"),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                16, 0, 16, 15), // adds space from bottom
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // pill shape
            ),
            // optional: make it pop

            duration: const Duration(seconds: 3),
          ));
        }
        if (updatedTask.notificationTime != null) {
          await NotificationHelper.updateNotificationState(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            elevation: 6,
            content: const Text("Task Updated and Scheduled Successfully!"),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(
                16, 0, 16, 15), // adds space from bottom
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // pill shape
            ),
            // optional: make it pop

            duration: const Duration(seconds: 3),
          ));
        }
      }

      if (result > 0) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update task")),
        );
      }
    } catch (e) {
      debugPrint("Error updating task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred while updating")),
      );
    }
  }

  void _showConfirmDialog() {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(title: const Text("Delete Task?"),
      content: const Text("You are about to delete a task. \n"
      "This will also clear it from completion tables. \n"
      "Continue?"),
      actions: <Widget>[
        MaterialButton(
          child: Text("Yes"),
          onPressed: () {
            Navigator.of(context).pop();
            _deleteTask();},
          color: Colors.red,),
          MaterialButton(
            child: Text("No"),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,)
      ]
      );
    },
    );
  }

  void _deleteTask() async {
    final dbHelper = DatabaseHelper();

    try {
      await dbHelper
          .deleteTask(widget.task.id!); // Delete the task from the database
      Navigator.pop(context,
          true); // Go back to the previous screen with a refresh signal
    } catch (e) {
      debugPrint("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete task!")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff8797b4),
        title: const Text(
          "Edit Task",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Color(0xff000000),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                "Task Name: ",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter task name",
                ),
              ),
              const SizedBox(
                height: 16,
              ),
            ]),

            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Task Type"),
              DropdownButton<String>(
                value: _selectedTaskType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedTaskType = newValue!;
                    _selectedDurationType = null;
                  });
                },
                items: [
                  "No Alert/Tracker",
                  "One-Time",
                  "Repetitive",
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
            ]),

            const SizedBox(height: 16),

            if (_selectedTaskType == "One-Time" ||
                _selectedTaskType == "Repetitive") ...[
              Text("Notification Type"),
              //Notif type is duration type
              Column(
                children: [
                  RadioListTile<String>(
                    title: Text("Notify after hours"),
                    value: "Hours",
                    groupValue: _selectedDurationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedDurationType = value;
                      });
                    },
                  ),
                  if (_selectedDurationType == "Hours") ...[
                    TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Enter hours"),
                    ),
                  ],
                  RadioListTile<String>(
                    title: Text("Notify after days"),
                    value: "Days",
                    groupValue: _selectedDurationType,
                    onChanged: (value) {
                      setState(() {
                        _selectedDurationType = value;
                      });
                    },
                  ),
                  if (_selectedDurationType == "Days") ...[
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Enter days"),
                    ),
                  ],
                  if (_selectedTaskType == "One-Time")
                    RadioListTile<String>(
                      title: Text("Set specific date/time"),
                      value: "Specific",
                      groupValue: _selectedDurationType,
                      onChanged: (value) {
                        setState(() {
                          _selectedDurationType = value;
                          _pickDateTime(context);
                        });
                      },
                    ),
                  if (_selectedDurationType == "Specific") ...[
                    Text(
                        "Selected Date: ${selectedDateString ?? 'Not selected'}")
                  ],
                ],
              ),
            ],

            const SizedBox(height: 16),
            if (_selectedTaskType == 'Repetitive')
              SwitchListTile(
                  title: Text("Enable auto-repetition?"),
                  subtitle: Text(
                      "Clicking this option will have the task automatically rescheduled regardless of pressing the 'Continue' notification button"),
                  value: _autoRepeat,
                  onChanged: (value) => setState(() => _autoRepeat = value)),

            Row(
              children: [
                Checkbox(
                  value: _showDetails,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _showDetails = newValue ?? false;
                    });
                  },
                ),
                const Text("Provide more info?"),
              ],
            ),
            const SizedBox(height: 16),
            if (_showDetails) ...[
              const Text("Details"),
              const SizedBox(height: 20),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter task details",
                ),
              ),
            ],

            if (_selectedTaskType != "No Alert/Tracker") ...[
              SwitchListTile(
                title: const Text("Notifications Enabled"),
                subtitle: const Text(
                    "If on, the task has a running notification scheduled."),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ],

            // Add this in the Column children, after the DELETE TASK button
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              MaterialButton(
                onPressed: _markTaskAsCompleteForTesting,
                color: const Color(0xff4CAF50), // Green color
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xff808080), width: 1),
                ),
                textColor: const Color(0xffffffff),
                height: 40,
                minWidth: 140,
                child: const Text(
                  "MARK COMPLETE (TEST)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            MaterialButton(
              onPressed: _updateTask,
              color: const Color(0xff8797b4),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Color(0xff808080), width: 1),
              ),
              textColor: const Color(0xffffffff),
              height: 40,
              minWidth: 140,
              child: const Text(
                "SAVE CHANGES",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),

            const SizedBox(height: 16),

            MaterialButton(
              onPressed: _showConfirmDialog,
              color: const Color(0xffc98ca3),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Color(0xff808080), width: 1),
              ),
              textColor: const Color.fromARGB(255, 255, 255, 255),
              height: 40,
              minWidth: 140,
              child: const Text(
                "DELETE TASK",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _hoursController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
