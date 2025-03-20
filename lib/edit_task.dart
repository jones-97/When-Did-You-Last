import 'package:flutter/material.dart';
import 'Models/task.dart';
import 'Util/database_helper.dart';

class EditTask extends StatefulWidget {
  final Task currentTask;

  const EditTask({super.key, required this.currentTask});

  @override
  _EditTaskState createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  final TextEditingController _nameController = TextEditingController();
  TextEditingController _notifyController = TextEditingController();
  bool _enableAlert = false;
  int? _notifyHours;
  int? _notifyDays;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    // Initialize the form fields with the current task's properties
    _nameController.text = widget.currentTask.name;

    // Check if the task has alerts enabled
    _enableAlert = widget.currentTask.notifyHours != null ||
        widget.currentTask.notifyDays != null ||
        widget.currentTask.notifyDate != null;

    _notifyHours = widget.currentTask.notifyHours;
    _notifyDays = widget.currentTask.notifyDays;
    _selectedDate = widget.currentTask.notifyDate != null
        ? DateTime.parse(widget.currentTask.notifyDate!)
        : null;

    if (_notifyHours != null) {
      _notifyController.text = _notifyHours.toString();
    } else if (_notifyDays != null) {
      _notifyController.text = _notifyDays.toString();
    } else if (_selectedDate != null) {
      _notifyController.text = _selectedDate.toString();
    }

    // Preselect the alert type if alerts are enabled
    if (_enableAlert) {
      if (widget.currentTask.notifyHours != null) {
        _notifyHours = widget.currentTask.notifyHours;
      } else if (widget.currentTask.notifyDays != null) {
        _notifyDays = widget.currentTask.notifyDays;
      } else if (widget.currentTask.notifyDate != null) {
        _selectedDate = DateTime.parse(widget.currentTask.notifyDate!);
      }
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _notifyHours = null;
        _notifyDays = null;
      });
    }
  }

  void _updateTask() async {

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task name is required!")),
      );
      return;
    }

    final dbHelper = DatabaseHelper();

    // Create an updated task object
    final updatedTask = Task(
      id: widget.currentTask.id, // Preserve the task ID
      name: _nameController.text,
      notifyHours: _enableAlert ? _notifyHours : null,
      notifyDays: _enableAlert ? _notifyDays : null,
      notifyDate: _enableAlert ? _selectedDate?.toIso8601String() : null,
    );

    try {
      await dbHelper.updateTask(updatedTask); // Update the task in the database
      Navigator.pop(context,
          true); // Go back to the previous screen with a refresh signal
    } catch (e) {
      print("Error updating task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update task!")),
      );
    }
    
  }

  void _deleteTask() async {
    final dbHelper = DatabaseHelper();

    try {
      await dbHelper.deleteTask(
          widget.currentTask.id!); // Delete the task from the database
      Navigator.pop(context,
          true); // Go back to the previous screen with a refresh signal
    } catch (e) {
      print("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete task!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // return WillPopScope(
    //   onWillPop: () async {
    //     Navigator.pop(context, true);
    //     return false;
    //   },
    //   child:
      
      return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        elevation: 4,
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xffe8d63a),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "Edit Task",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Color(0xff000000),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xff212435),
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context, true); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
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
            SwitchListTile(
              title: const Text("Task Alert Status"),
              value: _enableAlert,
              activeColor: const Color(0xff3a57e8),
              activeTrackColor: const Color(0xff92c6ef),
              inactiveThumbColor: const Color(0xff9e9e9e),
              inactiveTrackColor: const Color(0xffe0e0e0),
              onChanged: (value) {
                setState(() {
                  _enableAlert = value;
                  if (!value) {
                    _notifyHours = null;
                    _notifyDays = null;
                    _selectedDate = null;
                  }
                });
              },
            ),
            if (_enableAlert) ...[
              const Text("Choose One Alert Option",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text("Notify after hours"),
                leading: Radio(
                  value: 1,
                  groupValue: _notifyHours != null
                      ? 1
                      : (_notifyDays != null
                          ? 2
                          : (_selectedDate != null ? 3 : null)),
                  onChanged: (value) {
                    setState(() {
                      _notifyHours = 1; // Default value
                      _notifyDays = null;
                      _selectedDate = null;
                    });
                  },
                ),
              ),
              if (_notifyHours != null)
                TextField(
                  controller: _notifyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Enter hours"),
                  onChanged: (value) {
                    _notifyHours = int.tryParse(value);
                  },
                ),
              ListTile(
                title: const Text("Notify after days"),
                leading: Radio(
                  value: 2,
                  groupValue: _notifyDays != null
                      ? 2
                      : (_notifyHours != null
                          ? 1
                          : (_selectedDate != null ? 3 : null)),
                  onChanged: (value) {
                    setState(() {
                      _notifyHours = null;
                      _notifyDays = 1; // Default value
                      _selectedDate = null;
                    });
                  },
                ),
              ),
              if (_notifyDays != null)
                TextField(
                  controller: _notifyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Enter days"),
                  onChanged: (value) {
                    _notifyDays = int.tryParse(value);
                  },
                ),
              ListTile(
                title: const Text("Set specific date/time"),
                leading: Radio(
                  value: 3,
                  groupValue: _selectedDate != null
                      ? 3
                      : (_notifyHours != null
                          ? 1
                          : (_notifyDays != null ? 2 : null)),
                  onChanged: (value) {
                    _pickDate(context);
                  },
                ),
              ),
              if (_selectedDate != null)
                Text("Selected Date: ${_selectedDate.toString()}"),
            ],
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
      )
      );
    //   )
    // );
  }
}
