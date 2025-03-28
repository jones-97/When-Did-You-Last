class Task {
  int? id;
  String name;
  String? details;
  String taskType; //no-alert/tracker, one-time, repetitive
  String repeatType; //none, minute, hourly, daily, specified
  int? intervalValue; //to store EXACT interval values for hourly and daily timed tasks; datetime.now reduces the duration
  int? customInterval; // Nullable, for specifically-time reminders; future possible implementation
  int? notificationTime;
  bool notificationsPaused;
  //   List<String> completedDates = []; // Store multiple completion dates

  Task({
    this.id,
    required this.name,
    this.details,
    required this.taskType,
    required this.repeatType,
    this.customInterval,
    this.notificationTime,
    this.notificationsPaused = false,
  });

  // Convert a Task object to a Map (for saving to the database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'task_type': taskType,
      'repeat_type': repeatType,
      'custom_interval': customInterval,
      'notification_time': notificationTime,
      'notifications_paused': notificationsPaused ? 1 : 0,
    };
  }

  // Convert a Map from the database into a Task object
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      details: map['details'],
      taskType: map['task_type'],
      repeatType: map['repeat_type'],
      customInterval: map['custom_interval'],
      notificationTime: map['notification_time'],
      notificationsPaused: map['notifications_paused'] == 1,
    );
  }
}
