enum NotificationTargetType { student, teacher, schoolClass }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String title;
  final String message;
  final String date;
  final NotificationTargetType targetType;
  final String targetId;

  NotificationItem copyWith({
    String? title,
    String? message,
    String? date,
    NotificationTargetType? targetType,
    String? targetId,
  }) {
    return NotificationItem(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'targetType': _targetTypeToString(targetType),
      'targetId': targetId,
    };
  }

  static String _targetTypeToString(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.student:
        return 'student';
      case NotificationTargetType.teacher:
        return 'teacher';
      case NotificationTargetType.schoolClass:
        return 'schoolClass';
    }
  }

  static NotificationTargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return NotificationTargetType.teacher;
      case 'schoolClass':
        return NotificationTargetType.schoolClass;
      case 'student':
      default:
        return NotificationTargetType.student;
    }
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      targetType: _targetTypeFromString((map['targetType'] ?? '').toString()),
      targetId: (map['targetId'] ?? '').toString(),
    );
  }
}
