import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:when_did_you_last/intro_permissions.dart';
import 'package:when_did_you_last/new_task.dart';
import 'package:when_did_you_last/test_notification.dart';
import 'package:when_did_you_last/tutorial_screen.dart';
import 'tasks_list.dart';
import 'settings.dart';
import 'date_view.dart';
// import 'main.dart';
// import 'main.dart';
import 'Util/database_helper.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper();
  Set<DateTime> _completedTaskDates = {};
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCompletedDates();
  }

  // Normalize date (remove time component)
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _loadCompletedDates() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results =
        await db.query('completed_tasks');

    setState(() {
      _completedTaskDates = results
          .map((row) => _stripTime(DateTime.parse(row['completed_date'])))
          .toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 83, 214, 184),
        title: const Text("When Did You Last...?"),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Color(0xff212435), size: 24),
            onSelected: (value) {
              if (value == 'Task View') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TasksList()),
                );
              } else if (value == 'Settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Settings()),
                );
              } else if (value == 'Test Notification') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TestNotificationScreen()),
                );
              } else if (value == 'Permissions') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IntroPermissionsScreen(
                      onComplete:  () {
                        Navigator.pop(context);
                      },
                  ),
                ));
              } else if (value == 'Tutorial') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TutorialScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Task View', child: Text('Task View')),
              const PopupMenuItem(
                value: 'Tutorial',
                child: Text('How to Use'),
              ),

              const PopupMenuItem(
                  value: 'Test Notification', child: Text('Test Notification')),
              const PopupMenuItem(
                value: 'Permissions',
                child: Text('Permissions Setup'),
              ),
              const PopupMenuItem(value: 'Settings', child: Text('Settings')),

              // ✅ New item
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1), // Adjust the range as needed
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month'
            }, // ✅ Only allow month view
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true, // ✅ Hides the format button
            ),
            selectedDayPredicate: (day) =>
                _completedTaskDates.contains(_stripTime(day)),
            onDaySelected: (selectedDay, focusedDay) async {
              if (selectedDay.isAfter(DateTime.now())) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("You cannot select future dates.")),
                );
                return;
              }

              bool? shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DateView(selectedDate: selectedDay)),
              );

              if (shouldRefresh == true) {
                _loadCompletedDates(); // Refresh the calendar when returning
              }
            },

            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(
                    255, 115, 239, 182), // Force green for selected dates
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.lightBlue, // Keep today's date blue
                shape: BoxShape.circle,
              ),
              defaultDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
            ),

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                bool isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                bool isCompleted =
                    _completedTaskDates.contains(_stripTime(day));
                bool isFutureDate = day.isAfter(DateTime.now());

                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xffceebe4)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isFutureDate
                            ? (isDarkMode
                                ? Colors.black
                                : Colors.grey) // Future dates
                            : (isDarkMode
                                ? Colors.white
                                : Colors.black), // Accessible dates

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add new task",
        backgroundColor: const Color.fromARGB(255, 83, 214, 184),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => NewTask()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
