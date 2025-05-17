// tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:when_did_you_last/home_page.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.orange[800],
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          fontSize: 16,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('How To Use'),
        backgroundColor: const Color.fromARGB(255, 245, 184, 43),
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
                Image.asset('images/calendar_view.jpg', width: 200, height: 200),
                const SizedBox(height: 8),

                Text(
                  "When you complete a task on a specific date, that date is highlighted in green on the calendar. "
                  "Tapping the date shows the Date View, where you can see all completed tasks from that day.\n",
                  style: bodyStyle,
                ),
                Image.asset('images/date_view.jpg', width: 200, height: 200),
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
                Image.asset('images/new_task_view_unpopulated.jpg', width: 200, height: 200),
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
                        text: "Used to log when you last did an activity. No reminders are set.\n\n",
                      ),
                      const TextSpan(
                        text: "Reminder Tasks: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: "Send you notifications. You can choose between:\n"
                            "• One-Time – fires once.\n"
                            "• Repetitive – repeats at a custom interval.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text("Task View", style: headlineStyle),
                const SizedBox(height: 8),
                Image.asset('images/tasks_list_view_unpopulated.jpg', width: 200, height: 350),
                Text(
                  "This screen shows all tasks you've created — both Tracker and Reminder types — in one place.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 24),

                Text("Settings", style: headlineStyle),
                const SizedBox(height: 8),
                Image.asset('images/settings.jpg', width: 200, height: 200),
                Text(
                  "From the Settings screen, you can customize how the app works — including notification behavior, task tracking, and more.",
                  style: bodyStyle,
                ),
                const SizedBox(height: 40),
                Center(

                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyHomePage())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff676690),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

