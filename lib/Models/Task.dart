class Task {
  int? id;
  String name;
  String? details;
  String taskType; //No Alert/Tracker, One-Time, Repetitive
  String durationType; //None, Minutes, Hours, Days, Specific
  int? customInterval; // Nullable, for specifically-time reminders; future possible implementation
  int? notificationTime; //to store EXACT values tasks due dates and times; a store for specific task types
  bool notificationsPaused;
  //   List<String> completedDates = []; // Store multiple completion dates

  Task({
    this.id,
    required this.name,
    this.details,
    required this.taskType,
    required this.durationType,
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
      'duration_type': durationType,
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
      durationType: map['duration_type'],
      customInterval: map['custom_interval'],
      notificationTime: map['notification_time'],
      notificationsPaused: map['notifications_paused'] == 1,
    );
  }
  
  Task copyWith({
    int? id,
    String? name,
    String? details,
    String? taskType,
    String? durationType,
    int? notificationTime,
    bool? notificationsPaused,
    int? customInterval,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      taskType: taskType ?? this.taskType,
      durationType: durationType ?? this.durationType,
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsPaused: notificationsPaused ?? this.notificationsPaused,
      customInterval: customInterval ?? this.customInterval,
    );
  }
}



