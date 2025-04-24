// tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:when_did_you_last/home_page.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

 // @override
  /*
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("How to Use the App")),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to 'When Did You Last'?",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text("• The following is your menu screen'."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML

                    const SizedBox(height: 20),
                    const Text(
                        "• Tap '+' to create a new task wherever you see the button 'New Task'."),
                    const SizedBox(height: 8),
                    //  Image.asset("assets/images/tutorial_add_task.png"),

                    const SizedBox(height: 20),
                    const Text(
                        "• Choose a Task Type: No-Alert/Tracker, One-Time or Repetitive."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML
                    //
                    //
                    const SizedBox(height: 20),
                    const Text(
                        "• No-Alert/Tracker tasks, as in the name, do not have notifications and act as trackers for tasks."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML

                    const SizedBox(height: 20),
                    const Text(
                        "• You can provide task details to help you remember what a task is about."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML

                    const SizedBox(height: 20),
                    const Text(
                        "• Access the Settings screen to handle notifications."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML

                    const SizedBox(height: 20),
                    const Text(
                        "• Use the menu to revisit permissions or this tutorial."),
                    const SizedBox(height: 8),
                    // Image.asset("assets/images/tutorial_add_task.png"),
                    //ADD IMAGES TO YOUR PUBSCPEC.YAML

                    const Spacer(),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, '/'); // or pop if returning
                        },
                        child: const Text("Get Started!"),
                      ),
                    )
                  ],
                ),
              ),
            ])));
  }
*/

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("How to Use the App"), backgroundColor: const Color.fromARGB(255, 249, 232, 191),),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            const Text(
            "Welcome to ",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "When Did You Last...?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 76, 232, 185)),
          ),
          ],
          ),
          
          const SizedBox(height: 16),
          const Text("• The following is your home screen.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),

          const Text("  Click the menu item on the top right to access other options.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• Tap '+' to create a new task wherever you see 'New Task'.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• Choose a Task Type: No-Alert/Tracker, One-Time or Repetitive.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• No-Alert/Tracker tasks act as trackers without notifications.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• Provide task details to help you remember.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• Access the Settings screen to handle notifications.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),

          const SizedBox(height: 20),
          const Text("• Use the menu to revisit permissions or this tutorial.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          const SizedBox(height: 30),

          Center(
            child: MaterialButton(
               color: const Color(0xff676690),
                elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Color(0xff808080), width: 1),
                    ),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyHomePage()));
              },
              child: const Text("Get Started!", style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      ),
    ),
  );
}



}
