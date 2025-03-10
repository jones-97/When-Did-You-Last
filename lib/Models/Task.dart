
class Task {
  int? id;
  String name;
  bool completed;
  int? notifyHours; // Nullable, for hour-based reminders
  int? notifyDays;  // Nullable, for day-based reminders
  String? notifyDate; // Nullable, for specific date reminders

  Task({
    this.id,
    required this.name,
    this.completed = false,
    this.notifyHours,
    this.notifyDays,
    this.notifyDate,
  });

  // Convert Task to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completed': completed ? 1 : 0,
      'notify_hours': notifyHours,
      'notify_days': notifyDays,
      'notify_date': notifyDate,
    };
  }

  // Convert Map from SQLite to Task Object
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      completed: map['completed'] == 1,
      notifyHours: map['notify_hours'],
      notifyDays: map['notify_days'],
      notifyDate: map['notify_date'],
    );
  }
}
