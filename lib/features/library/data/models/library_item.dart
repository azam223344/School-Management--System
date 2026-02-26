enum LibraryTargetType { student, teacher, schoolClass }

class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.bookName,
    required this.dueDate,
    required this.targetType,
    required this.targetId,
    required this.returned,
  });

  final String id;
  final String bookName;
  final String dueDate;
  final LibraryTargetType targetType;
  final String targetId;
  final bool returned;

  LibraryItem copyWith({
    String? bookName,
    String? dueDate,
    LibraryTargetType? targetType,
    String? targetId,
    bool? returned,
  }) {
    return LibraryItem(
      id: id,
      bookName: bookName ?? this.bookName,
      dueDate: dueDate ?? this.dueDate,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      returned: returned ?? this.returned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookName': bookName,
      'dueDate': dueDate,
      'targetType': _targetTypeToString(targetType),
      'targetId': targetId,
      'returned': returned,
    };
  }

  static String _targetTypeToString(LibraryTargetType type) {
    switch (type) {
      case LibraryTargetType.student:
        return 'student';
      case LibraryTargetType.teacher:
        return 'teacher';
      case LibraryTargetType.schoolClass:
        return 'schoolClass';
    }
  }

  static LibraryTargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return LibraryTargetType.teacher;
      case 'schoolClass':
        return LibraryTargetType.schoolClass;
      case 'student':
      default:
        return LibraryTargetType.student;
    }
  }

  factory LibraryItem.fromMap(Map<String, dynamic> map) {
    return LibraryItem(
      id: (map['id'] ?? '').toString(),
      bookName: (map['bookName'] ?? '').toString(),
      dueDate: (map['dueDate'] ?? '').toString(),
      targetType: _targetTypeFromString((map['targetType'] ?? '').toString()),
      targetId: (map['targetId'] ?? '').toString(),
      returned: map['returned'] == true,
    );
  }
}
