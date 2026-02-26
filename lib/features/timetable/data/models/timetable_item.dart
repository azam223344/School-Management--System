class TimetableItem {
  const TimetableItem({
    required this.id,
    required this.day,
    required this.time,
    required this.subject,
    required this.teacherId,
    required this.classId,
  });

  final String id;
  final String day;
  final String time;
  final String subject;
  final String teacherId;
  final String classId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'time': time,
      'subject': subject,
      'teacherId': teacherId,
      'classId': classId,
    };
  }

  factory TimetableItem.fromMap(Map<String, dynamic> map) {
    return TimetableItem(
      id: (map['id'] ?? '').toString(),
      day: (map['day'] ?? '').toString(),
      time: (map['time'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      teacherId: (map['teacherId'] ?? '').toString(),
      classId: (map['classId'] ?? '').toString(),
    );
  }
}
