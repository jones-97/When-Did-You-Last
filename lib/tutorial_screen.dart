// tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:when_did_you_last/app_lifecycle_manager.dart';
import 'package:when_did_you_last/home_page.dart';

class TutorialScreen extends StatefulWidget {

  const TutorialScreen({super.key});

   @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {

  Future<void> _gotIt() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tutorial_completed', true);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => AppLifecycleManager(child: const MyHomePage()),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange[200],
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          fontSize: 16,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('How To Use'),
        backgroundColor: const Color.fromARGB(255, 175, 110, 124),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Home Screen", style: headlineStyle),
                const SizedBox(height: 8),
                Image.asset('assets/images/calendar_view.jpg',
                    width: 200, height: 200,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
                const SizedBox(height: 8),
                Text(
                  "When you complete a task on a specific date, that date is highlighted in green on the calendar. "
                  "Tapping the date shows the Date View, where you can see all completed tasks from that day.\n",
                  style: bodyStyle,
                ),
                Image.asset('assets/images/date_view.jpg', width: 200, height: 200, errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
                const SizedBox(height: 24),
                Text("Menu Access", style: headlineStyle),
                const SizedBox(height: 8),
                Text(
                  "Tap the menu icon ☰ at the top right of the home screen to access key features like Task View, Settings, Permissions, and this Tutorial.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 24),
                Text("Adding New Tasks", style: headlineStyle),
                const SizedBox(height: 8),
                Text(
                  "Use the '+' button at the bottom right of the home screen to create a new task. "
                  "This takes you to the New Task screen.\n",
                  style: bodyStyle,
                ),
                Image.asset('assets/images/new_task_view_unpopulated.jpg',
                    width: 200, height: 200, errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
                const SizedBox(height: 24),
                Text("Types of Tasks", style: headlineStyle),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      const TextSpan(
                        text: "Tracker Tasks: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            "Used to log when you last did an activity. No reminders are set.\n\n",
                      ),
                      const TextSpan(
                        text: "Reminder Tasks: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            "Send you notifications. You can choose between:\n"
                            "• One-Time – fires once.\n"
                            "• Repetitive – repeats at a custom interval.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("Task View", style: headlineStyle),
                const SizedBox(height: 8),
                Image.asset('assets/images/tasks_list_view_unpopulated.jpg',
                    width: 200, height: 350, errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
                Text(
                  "This screen shows all tasks you've created — both Tracker and Reminder types — in one place.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 24),
                Text("Settings", style: headlineStyle),
                const SizedBox(height: 8),
                Image.asset('assets/images/settings.jpg', width: 200, height: 200, errorBuilder: (context, error, stackTrace) => Icon(Icons.error)),
                Text(
                  "From the Settings screen, you can customize how the app works — including notification behavior, task tracking, and more.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _gotIt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff676690),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
