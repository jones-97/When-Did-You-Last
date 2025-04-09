// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:when_did_you_last/Util/notifications_helper.dart';
import 'Util/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'Models/task.dart';
// import 'Util/notifications_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class NewTask extends StatefulWidget {
  @override
  _NewTaskState createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  String _selectedTaskType = "No Alert/Tracker";
  String? _selectedDurationType;
  int? _selectedTime;
  bool _showDetails = false;
  bool _autoRepeat = false;
  String? selectedDateString;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  // TimeOfDay? _defaultTaskTime;
  DateTime? _selectedDate;

/*
  Future<void> _pickDate(BuildContext context) async {
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hoursController.text.isEmpty;
        _daysController.text.isEmpty;
        selectedDateString = _selectedDate.toString();
      });
    }
  }

  void calculateDateTime(String? date) {
    DateTime current = DateTime.now();

     // SPECIFIC DATE/TIME REMINDER (Assuming input is HH:mm format)
        List<String> timeParts = date!.split(":");
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);

        DateTime nextNotificationTime = DateTime(current.year, current.month, current.day, hour, minute);
        if (current.isAfter(nextNotificationTime)) {
            // If the specified time has already passed today, schedule it for tomorrow
            nextNotificationTime = nextNotificationTime.add(const Duration(days: 1));
        }

        _selectedTime = nextNotificationTime.millisecondsSinceEpoch;
}

*/

// Update the _pickDate method to include time picking
  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
          debugPrint(
              "The selected date in pickedDateTime function $_selectedDate");
          selectedDateString =
              DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate!);
        });
      }
    }
  }

// Update the calculateDateTime method
  void calculateDateTime() {
    if (_selectedDate != null) {
      _selectedTime = _selectedDate!.millisecondsSinceEpoch;
      return;
    }

    if (_hoursController.text.isNotEmpty) {
      int hours = int.parse(_hoursController.text);
      DateTime nextNotificationTime =
          DateTime.now().add(Duration(hours: hours));
      _selectedTime = nextNotificationTime.millisecondsSinceEpoch;
    } else if (_daysController.text.isNotEmpty) {
      int days = int.parse(_daysController.text);
      DateTime nextNotificationTime = DateTime.now().add(Duration(days: days));
      _selectedTime = nextNotificationTime.millisecondsSinceEpoch;
    }
  }

/*
  Future<void> _saveTask() async {
    DateTime current = DateTime.now();

    if (_hoursController.text.isNotEmpty) {
      _daysController.text.isEmpty;
    int hours = int.parse(_hoursController.text);
    
  
    DateTime nextNotificationTime = current.add(Duration(hours: hours)); // Add user-provided hours

    int timestamp = nextNotificationTime.millisecondsSinceEpoch; // Convert to timestamp
    _selectedTime = timestamp; // Store as an int, not string
}

     if (_daysController.text.isNotEmpty) {
      _hoursController.text.isEmpty;
        // DAILY REMINDER
        int days = int.parse(_daysController.text);
        DateTime nextNotificationTime = current.add(Duration(days: days));
      _selectedTime = nextNotificationTime.millisecondsSinceEpoch;
    } 




     // Example for hourly task

    

    final dbHelper = DatabaseHelper();

    Task newTask = Task(
      name: _nameController.text,
      details: _showDetails ? _detailsController.text : null,
      taskType: _selectedTaskType,
      repeatType: _selectedNotificationType ?? "none",
      notificationTime: _selectedTime, // Modify this when implementing time storage
      notificationsPaused: false,
    );

    await dbHelper.insertTask(newTask);
    Navigator.pop(context); // Close screen after saving
  }
*/

// In the _saveTask method:
  Future<void> _saveTask() async {
    int? custom_interval;

    if (_selectedDurationType == "Specific" && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date and time")),
      );
      return;
    }

    // Calculate notification time based on selection

    int? notificationTime;

    if (_selectedDurationType == "Hours" && _hoursController.text.isNotEmpty) {
      notificationTime = DateTime.now()
          .add(Duration(hours: int.parse(_hoursController.text)))
          .millisecondsSinceEpoch;
    } else if (_selectedDurationType == "Days" &&
        _daysController.text.isNotEmpty) {
      notificationTime = DateTime.now()
          .add(Duration(days: int.parse(_daysController.text)))
          .millisecondsSinceEpoch;
    } else if (_selectedDurationType == "Specific" && _selectedDate != null) {
      notificationTime = _selectedDate!.millisecondsSinceEpoch;
    } else {
      notificationTime = null;
    }

    if (_selectedDurationType == 'Hours' && _hoursController.text.isNotEmpty) {
      custom_interval = int.tryParse(_hoursController.text);
    } else if (_selectedDurationType == 'Days' &&
        _daysController.text.isNotEmpty) {
      custom_interval = int.tryParse(_daysController.text);
    }

    final task = Task(
      name: _nameController.text,
      details: _showDetails ? _detailsController.text : null,
      taskType: _selectedTaskType,
      durationType: _selectedDurationType ?? "None",
      autoRepeat: _autoRepeat,
      customInterval: custom_interval ?? 0,
      notificationTime: notificationTime,
      notificationsPaused: false,
    );

    final id = await DatabaseHelper().insertTask(task);
    debugPrint("New task's id is $id");

    // First insert the task to get the auto-generated ID

    // Now update the task with the generated ID
    final taskWithId = task.copyWith(id: id);

    // Schedule notification with the actual ID
    // if (taskWithId.notificationTime != null) {
    //   await NotificationHelper.scheduleTaskNotification(taskWithId);
    // }

    // Schedule notification
    if (!kIsWeb && taskWithId.notificationTime != null) {
      try {
        // 1. First ensure notifications are initialized
        
        await NotificationHelper.scheduleNotification(taskWithId);
      } catch (e) {
        debugPrint("Error scheduling notification: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("Task saved but notification failed: ${e.toString()}")));
      }
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffe8d63a),
        title: const Text(
          "New Task",
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              obscureText: false,
              maxLines: 1,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.normal,
                fontSize: 14,
                color: Color(0xff000000),
              ),
              decoration: InputDecoration(
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide:
                      const BorderSide(color: Color(0xff000000), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide:
                      const BorderSide(color: Color(0xff000000), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide:
                      const BorderSide(color: Color(0xff000000), width: 1),
                ),
                hintText: "Enter Text",
                hintStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: 14,
                  color: Color(0xff000000),
                ),
                filled: true,
                fillColor: const Color(0xfff2f2f3),
                isDense: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Type Dropdown
                  Text("Task Type"),
                  DropdownButton<String>(
                    value: _selectedTaskType,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTaskType = newValue!;
                        _selectedDurationType =
                            null; // Reset notification selection
                      });
                    },
                    items: [
                      "No Alert/Tracker",
                      "One-Time",
                      "Repetitive",
                    ].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                  ),

                  SizedBox(height: 16),

                  // Show radio buttons if "One-Time" or "Repetitive" is selected
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
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: "Enter hours"),
                            controller: _hoursController,
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
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: "Enter days"),
                            controller: _daysController,
                          ),
                        ],
                        if (_selectedTaskType ==
                            "One-Time") // Only show this for One-Time tasks
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
                          Text("Selected Date Picked: $selectedDateString")
                        ],
                        if (_selectedTaskType == 'Repetitive') 
                        SwitchListTile(
                          title: Text("Enable auto-repetition?"),
                          subtitle: Text("Clicking this option will have the task automatically rescheduled regardless of pressing the 'Continue' notification button"),
                          value: _autoRepeat, 
                          onChanged: (value) => setState(() => _autoRepeat = value)
                          )
                      ],
                    ),
                  ],

                  SizedBox(height: 16),

                  // Checkbox for "Provide more info?"
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

                  // Show Details field when checkbox is checked
                  if (_showDetails) ...[
                    Text("Details"),
                    TextField(controller: _detailsController),
                  ],

                  SizedBox(height: 20),

                  MaterialButton(
                    onPressed: _saveTask,
                    color: const Color(0xffe8d63a),
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: Color(0xff808080), width: 1),
                    ),
                    child: const Text('Save Task',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
