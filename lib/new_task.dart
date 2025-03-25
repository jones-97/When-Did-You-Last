///File download from FlutterViz- Drag and drop a tools. For more details visit https://flutterviz.io/
library;

import 'package:flutter/material.dart';
import 'Util/database_helper.dart';
import 'Models/task.dart';
import 'Util/notifications_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/*
void _saveTask() async {
  if (_selectedDate != null) {
    await NotificationHelper.scheduleNotification(
      0,
      "Task Reminder",
      "Don't forget: $_taskName",
      _selectedDate!,
    );
  }
}
*/

class NewTask extends StatefulWidget {
  @override
  _NewTaskState createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {



final TextEditingController _nameController = TextEditingController();
bool _enableAlert = false;
int? _notifyHours;
int? _notifyDays;
TimeOfDay? _defaultTaskTime;

// final TextEditingController _hoursController = TextEditingController();
// final TextEditingController _daysController = TextEditingController();
DateTime? _selectedDate;

@override
void initState() {
  super.initState();
  _loadDefaultTime();
}


Future<void> _loadDefaultTime() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('defaultTaskHour') && prefs.containsKey('defaultTaskMinute')) {
    setState(() {
      _defaultTaskTime = TimeOfDay(
        hour: prefs.getInt('defaultTaskHour') ?? 8,
        minute: prefs.getInt('defaultTaskMinute') ?? 0,
      );
    });
  }
}
  


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
        _notifyHours = null;
        _notifyDays = null;
        // _hoursController.text.isEmpty; 
        // _daysController.text.isEmpty; 
      });
  }
}

void _saveTask() async {
  if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task name is required!")),
    );
    return;
  }

  final dbHelper = DatabaseHelper();

  DateTime? notifyDate = _selectedDate;
  
  if (notifyDate != null && _defaultTaskTime != null) {
    notifyDate = DateTime(
      notifyDate.year,
      notifyDate.month,
      notifyDate.day,
      _defaultTaskTime!.hour,
      _defaultTaskTime!.minute,
    );
  }

  final task = Task(
    name: _nameController.text,
    notifyHours: _enableAlert ? _notifyHours : null,
    notifyDays: _enableAlert ? _notifyDays : null,
    notifyDate: _enableAlert ? notifyDate?.toIso8601String() : null,
    notificationsPaused: _enableAlert ? 0 : 1,
  );

  try {
    int taskId = await dbHelper.insertTask(task);

    // ✅ Only schedule a notification if an alert is set
    if (_enableAlert) {
      if (notifyDate != null) {
        
        await NotificationHelper.scheduleNotification(
          taskId, // Unique notification ID
          "Task Reminder",
          "Don't forget: ${task.name}",
          notifyDate,
        );
      } else if (_notifyHours != null) {
        await NotificationHelper.scheduleNotification(
          taskId,
          "Task Reminder",
          "Don't forget: ${task.name}",
          DateTime.now().add(Duration(hours: _notifyHours!)),
        );
      } else if (_notifyDays != null) {
        await NotificationHelper.scheduleNotification(
          taskId,
          "Task Reminder",
          "Don't forget: ${task.name}",
          DateTime.now().add(Duration(days: _notifyDays!)),
        );
      }
    }

    Navigator.pop(context, true);
     // Refresh task list after saving
  } catch (e) {
    debugPrint("Error saving task: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to save task!")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      
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
     
      body: //MAIN BODY
      SingleChildScrollView(
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
                  borderSide: const BorderSide(color: Color(0xff000000), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Color(0xff000000), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  borderSide: const BorderSide(color: Color(0xff000000), width: 1),
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
              title: const Text("Enable Task Alert?"),
              value: _enableAlert,
              activeColor: const Color(0xff3a57e8),
              activeTrackColor: const Color(0xff92c6ef),
              inactiveThumbColor: const Color(0xff9e9e9e),
              inactiveTrackColor: const Color(0xffe0e0e0),
               onChanged: (value) {
                setState(() {
                  _enableAlert= !_enableAlert;
                  _checkNotificationStatus();

                  if (!value) {
                    _notifyHours = null;
                    _notifyDays = null;
                    // _hoursController.text.isEmpty;
                    // _daysController.text.isEmpty;
                    _selectedDate = null;
              
                    
                  }
                }); 
              },
            ),
           if (_enableAlert) ...[
            const Text("Choose One Alert Option", style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
                title: const Text("Notify after hours"),
                leading: Radio(
                  value: 1,
                  groupValue: _notifyHours != null ? 1 : null,
                  onChanged: (value) {
                    setState(() {
                      _notifyHours = 1; // Default value
                      _notifyDays =  null;
                      _selectedDate = null;
                    });
                  },
                ),
              ),
              if (_notifyHours != null)
                TextField(
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
                  groupValue: _notifyDays != null ? 2 : null,
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
                  groupValue: _selectedDate != null ? 3 : null,
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
              onPressed: _saveTask,
              color: const Color(0xffe8d63a),
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
                "CREATE",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ),
          ),
          ]
      )
      ),
      )
    );
  }
  
  void _checkNotificationStatus() async {
    await NotificationHelper.requestNotificationPermissions(context);
  }
}











//                 TextField(
//                     controller: _hoursController,
//                     keyboardType: TextInputType.number,
//                     onChanged: (value) {
//                       notifyHours = int.tryParse(value);
//                     },
//                     obscureText: false,
//                     textAlign: TextAlign.start,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                     decoration: InputDecoration(
//                       disabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       hintText: "Enter Hours",
//                       hintStyle: const TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontStyle: FontStyle.normal,
//                         fontSize: 14,
//                         color: Color(0xff000000),
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xfff2f2f3),
//                       isDense: false,
//                       contentPadding:
//                           const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                     ),
//                   ),



//            ]
      
      
      


















//       Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           const Padding(
//             padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: Text(
//               "Task Name: ",
//               textAlign: TextAlign.start,
//               overflow: TextOverflow.clip,
//               style: TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontStyle: FontStyle.normal,
//                 fontSize: 14,
//                 color: Color(0xff000000),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: TextField(
//               controller: _nameController,
//               obscureText: false,
//               textAlign: TextAlign.start,
//               maxLines: 1,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontStyle: FontStyle.normal,
//                 fontSize: 14,
//                 color: Color(0xff000000),
//               ),
//               decoration: InputDecoration(
//                 disabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4.0),
//                   borderSide: const BorderSide(color: Color(0xff000000), width: 1),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4.0),
//                   borderSide: const BorderSide(color: Color(0xff000000), width: 1),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4.0),
//                   borderSide: const BorderSide(color: Color(0xff000000), width: 1),
//                 ),
//                 hintText: "Enter Text",
//                 hintStyle: const TextStyle(
//                   fontWeight: FontWeight.w400,
//                   fontStyle: FontStyle.normal,
//                   fontSize: 14,
//                   color: Color(0xff000000),
//                 ),
//                 filled: true,
//                 fillColor: const Color(0xfff2f2f3),
//                 isDense: false,
//                 contentPadding:
//                     const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: Text(
//               "Enable Task Alert?",
//               textAlign: TextAlign.start,
//               overflow: TextOverflow.clip,
//               style: TextStyle(
//                 fontWeight: FontWeight.w400,
//                 fontStyle: FontStyle.normal,
//                 fontSize: 14,
//                 color: Color(0xff000000),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: SwitchListTile(
//               value: _enableAlert,
//               onChanged: (value) {
//                 setState(() {
//                   _enableAlert= !_enableAlert;

//                   if (!value) {
//                     _hoursController.text = '';
//                     _daysController.text = ''null'';
                    
//                   }
//                 }); 
//               },
//               activeColor: const Color(0xff3a57e8),
//               activeTrackColor: const Color(0xff92c6ef),
//               inactiveThumbColor: const Color(0xff9e9e9e),
//               inactiveTrackColor: const Color(0xffe0e0e0),
//             ),
//           ),
//           Container(
//             margin: const EdgeInsets.all(0),
//             padding: const EdgeInsets.all(0),
//             width: 250,
//             height: 250,
//             decoration: BoxDecoration(
//               color: const Color(0x1f000000),
//               shape: BoxShape.rectangle,
//               borderRadius: BorderRadius.zero,
//               border: Border.all(color: const Color(0x4d9e9e9e), width: 1),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
//                   child: Text(
//                     "Hour(s): ",
//                     textAlign: TextAlign.start,
//                     overflow: TextOverflow.clip,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//                   child: TextField(
//                     controller: _hoursController,
//                     obscureText: false,
//                     textAlign: TextAlign.start,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                     decoration: InputDecoration(
//                       disabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       hintText: "Enter Text",
//                       hintStyle: const TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontStyle: FontStyle.normal,
//                         fontSize: 14,
//                         color: Color(0xff000000),
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xfff2f2f3),
//                       isDense: false,
//                       contentPadding:
//                           const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                     ),
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
//                   child: Text(
//                     "Day(s):",
//                     textAlign: TextAlign.start,
//                     overflow: TextOverflow.clip,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//                   child: TextField(
//                     controller: _daysController,
//                     obscureText: false,
//                     textAlign: TextAlign.start,
//                     maxLines: 1,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                     decoration: InputDecoration(
//                       disabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(4.0),
//                         borderSide:
//                             const BorderSide(color: Color(0xff000000), width: 1),
//                       ),
//                       hintText: "Enter Text",
//                       hintStyle: const TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontStyle: FontStyle.normal,
//                         fontSize: 14,
//                         color: Color(0xff000000),
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xfff2f2f3),
//                       isDense: false,
//                       contentPadding:
//                           const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                     ),
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
//                   child: Text(
//                     "Specific date and/or time:",
//                     textAlign: TextAlign.start,
//                     overflow: TextOverflow.clip,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w400,
//                       fontStyle: FontStyle.normal,
//                       fontSize: 14,
//                       color: Color(0xff000000),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.calendar_month),
//                   onPressed: () {
//                     _pickDate(context);
//                   },
//                   color: const Color(0xff212435),
//                   iconSize: 24,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
//             child: MaterialButton(
//               onPressed: _saveTask,
//               color: const Color(0xffffffff),
//               elevation: 0,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.zero,
//                 side: BorderSide(color: Color(0xff808080), width: 1),
//               ),
//               padding: const EdgeInsets.all(16),
//               textColor: const Color(0xff000000),
//               height: 40,
//               minWidth: 140,
//               child: const Text(
//                 "CREATE",
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w400,
//                   fontStyle: FontStyle.normal,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
