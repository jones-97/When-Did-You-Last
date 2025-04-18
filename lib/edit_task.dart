import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Models/task.dart';
import 'Util/database_helper.dart';
import 'Util/notifications_helper_old.dart';
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
  bool _notificationsPaused = false;
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
  _detailsController.text = widget.task.details ?? '';
  _autoRepeat = widget.task.autoRepeat;

    _initializeNotificationSettings();
    

  }


  void _initializeNotificationSettings() {
    // Set the radio button based on repeatType
    _selectedDurationType = widget.task.durationType == 'None' 
        ? null 
        : widget.task.durationType;
      // "No Alert/Tracker";
      //                 "One-Time";
      //                 "Repetitive";
    _selectedTaskType = widget.task.taskType == 'No Alert/Tracker' 
        ? null 
        : widget.task.taskType;

        if (widget.task.details != null) {
          _showDetails = true;
        }


  if (widget.task.customInterval != null) {
    // For tasks with stored custom interval
    if (widget.task.durationType == 'Days') {
      _daysController.text = widget.task.customInterval.toString();
    } 
    else if (widget.task.durationType == 'Hours') {
      _hoursController.text = widget.task.customInterval.toString();
    }
  }

  else if (widget.task.notificationTime != null) {
    // Fallback for legacy tasks without custom_interval

    final taskTime = DateTime.fromMillisecondsSinceEpoch(widget.task.notificationTime!);
    
    if (widget.task.durationType == 'Days') {
      // Calculate approximate days (rounded to nearest whole number)
      double days = (widget.task.notificationTime! - DateTime.now().millisecondsSinceEpoch) / 
                   (1000 * 60 * 60 * 24);
      _daysController.text = days.round().toString();
    }
    else if (widget.task.durationType == 'Hours') {
      double hours = (widget.task.notificationTime! - DateTime.now().millisecondsSinceEpoch) / 
                    (1000 * 60 * 60);
      _hoursController.text = hours.round().toString();
    }
    else if (widget.task.durationType == 'Specific') {
      _selectedDate = taskTime;
      selectedDateString = DateFormat('MMM dd, yyyy - hh:mm a').format(taskTime);
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
          selectedDateString = DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate!);
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
      _notificationTime = DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;
    }
  } 
  else if (_selectedDurationType == 'Days' && _daysController.text.isNotEmpty) {
    int days = int.tryParse(_daysController.text) ?? 0;
    if (days > 0) {
      _notificationTime = DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch;
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
  if (_selectedDurationType == 'Hours' && _hoursController.text.isNotEmpty) {
    customInterval = int.tryParse(_hoursController.text);
  } 
  else if (_selectedDurationType == 'Days' && _daysController.text.isNotEmpty) {
    customInterval = int.tryParse(_daysController.text);
  }

    
    final updatedTask = Task(
      id: widget.task.id,
      name: _nameController.text,
      details: _showDetails ? _detailsController.text : null,
      taskType: _selectedTaskType!,
      durationType: _selectedDurationType ?? "None",
      autoRepeat:  _autoRepeat,
      notificationTime: _notificationTime,
      notificationsPaused: _notificationsPaused,
      customInterval: customInterval ?? 0, //stores original interval value eg 1 hour, 2 days
    );

    final result = await DatabaseHelper().updateTask(updatedTask);

    //SCHEDULE NOTIFICATION
  if (!kIsWeb) {
      if (updatedTask.taskType != "No Alert/Tracker" && updatedTask.notificationTime != null) {
    await NotificationHelper.scheduleNotification(updatedTask);
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

    void _deleteTask() async {
    final dbHelper = DatabaseHelper();

    try {
      await dbHelper.deleteTask(
          widget.task.id!); // Delete the task from the database
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
        backgroundColor: const Color(0xffe8d63a),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Task Name: ",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 14,
                  color: Color(0xff000000),
              ),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter task name",
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Task Type"),
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

                    SizedBox(height: 16),

                    if (_selectedTaskType == "One-Time" || _selectedTaskType == "Repetitive") ...[
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
                            Text("Selected Date: ${selectedDateString ?? 'Not selected'}")
                          ],
                        ],
                      ),
                    ],

                    SizedBox(height: 16),
                    if (_selectedTaskType == 'Repetitive') 
                        SwitchListTile(
                          title: Text("Enable auto-repetition?"),
                          subtitle: Text("Clicking this option will have the task automatically rescheduled regardless of pressing the 'Continue' notification button"),
                          value: _autoRepeat, 
                          onChanged: (value) => setState(() => _autoRepeat = value)
                          ),

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
                        Text("Provide more info?"),
                      ],
                    ),

                    if (_showDetails) ...[
                      Text("Details"),
                      TextField(
                        controller: _detailsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter task details",
                        ),
                      ),
                    ],
                    
                  if (_selectedTaskType != "No Alert/Tracker") ... [
                      SwitchListTile(
                      title: Text("Disable Task?"),
                      value: _notificationsPaused,
                      onChanged: (value) {
                        setState(() {
                          _notificationsPaused = value;
                        });
                      },
                    ),

                  ],
                  

                    SizedBox(height: 20),

                    Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: MaterialButton(
                onPressed: _updateTask,
                color: const Color(0xffffffff),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff808080), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                textColor: const Color(0xff000000),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: MaterialButton(
                onPressed: _deleteTask,
                color: const Color.fromARGB(255, 167, 53, 53),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff808080), width: 1),
                ),
                padding: const EdgeInsets.all(16),
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
            ),
                  ],
                ),
              ),
            ],
          ),
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
