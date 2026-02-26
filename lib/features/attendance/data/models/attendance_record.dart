class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.present,
  });

  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final bool present;

  AttendanceRecord copyWith({bool? present}) {
    return AttendanceRecord(
      id: id,
      classId: classId,
      studentId: studentId,
      date: date,
      present: present ?? this.present,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'present': present,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final rawDate = (map['date'] ?? '').toString();
    final parsed = DateTime.tryParse(rawDate) ?? DateTime.now();
    return AttendanceRecord(
      id: (map['id'] ?? '').toString(),
      classId: (map['classId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      date: DateTime(parsed.year, parsed.month, parsed.day),
      present: map['present'] == true,
    );
  }
}
