class Task {
  int? id;
  int? notificationId;
  String name;
  String? details;
  String taskType; //No Alert/Tracker, One-Time, Repetitive
  String durationType; //None, Minutes, Hours, Days, Specific
  bool autoRepeat; //0 or 1, false or true (Respectively)
  int? customInterval; // Nullable, for specifically-time reminders; future possible implementation
  int? notificationTime;
  bool isActive; //to store EXACT values tasks due dates and times; a store for specific task types
  bool notificationsEnabled;
  //   List<String> completedDates = []; // Store multiple completion dates

  Task({
    this.id,
    this.notificationId,
    required this.name,
    this.details,
    required this.taskType,
    required this.durationType,
    this.autoRepeat = false,
    this.customInterval,
    this.notificationTime,
    this.isActive = true,
    this.notificationsEnabled = true,
  });

  // Convert a Task object to a Map (for saving to the database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notification_id' : notificationId,
      'name': name,
      'details': details,
      'task_type': taskType,
      'duration_type': durationType,
      'auto_repeat' : autoRepeat ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'custom_interval': customInterval,
      'notification_time': notificationTime,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
    };
  }

  // Convert a Map from the database into a Task object
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      notificationId: map['notification_id'],
      name: map['name'],
      details: map['details'],
      taskType: map['task_type'],
      durationType: map['duration_type'],
      autoRepeat: map['auto_repeat'] == 1,
      customInterval: map['custom_interval'],
      notificationTime: map['notification_time'],
      isActive: map['is_active'] == 1,
      notificationsEnabled: map['notifications_enabled'] == 1,
    );
  }
  
  Task copyWith({
    int? id,
    int? notificationId,
    String? name,
    String? details,
    String? taskType,
    String? durationType,
    bool? autoRepeat,
    int? notificationTime,
    bool? isActive,
    bool? notificationsEnabled,
    int? customInterval,
  }) {
    return Task(
      id: id ?? this.id,
      notificationId: this.notificationId,
      name: name ?? this.name,
      details: details ?? this.details,
      taskType: taskType ?? this.taskType,
      durationType: durationType ?? this.durationType,
      autoRepeat: autoRepeat ?? this.autoRepeat,
      notificationTime: notificationTime ?? this.notificationTime,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      customInterval: customInterval ?? this.customInterval,
    );
  }
}



