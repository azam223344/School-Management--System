enum ExamTargetType { student, teacher, schoolClass }

class ExamItem {
  const ExamItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String title;
  final String subject;
  final String date;
  final ExamTargetType targetType;
  final String targetId;

  ExamItem copyWith({
    String? title,
    String? subject,
    String? date,
    ExamTargetType? targetType,
    String? targetId,
  }) {
    return ExamItem(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'date': date,
      'targetType': _targetTypeToString(targetType),
      'targetId': targetId,
    };
  }

  static String _targetTypeToString(ExamTargetType type) {
    switch (type) {
      case ExamTargetType.student:
        return 'student';
      case ExamTargetType.teacher:
        return 'teacher';
      case ExamTargetType.schoolClass:
        return 'schoolClass';
    }
  }

  static ExamTargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return ExamTargetType.teacher;
      case 'schoolClass':
        return ExamTargetType.schoolClass;
      case 'student':
      default:
        return ExamTargetType.student;
    }
  }

  factory ExamItem.fromMap(Map<String, dynamic> map) {
    return ExamItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      targetType: _targetTypeFromString((map['targetType'] ?? '').toString()),
      targetId: (map['targetId'] ?? '').toString(),
    );
  }
}
