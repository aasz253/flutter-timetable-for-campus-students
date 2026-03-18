class Course {
  final int? id;
  final String name;
  final String location;
  final String lecturer;
  final int weekday; // 1 = Monday ... 7 = Sunday
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final bool notificationsEnabled;

  Course({
    this.id,
    required this.name,
    required this.location,
    required this.lecturer,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.notificationsEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'lecturer': lecturer,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      name: map['name'] as String,
      location: map['location'] as String? ?? '',
      lecturer: map['lecturer'] as String? ?? '',
      weekday: map['weekday'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      notificationsEnabled: (map['notifications_enabled'] as int? ?? 0) == 1,
    );
  }
}

