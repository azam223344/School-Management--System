class SubjectItem {
  const SubjectItem({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherId,
    required this.classId,
  });

  final String id;
  final String name;
  final String code;
  final String teacherId;
  final String classId;

  SubjectItem copyWith({
    String? name,
    String? code,
    String? teacherId,
    String? classId,
  }) {
    return SubjectItem(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'teacherId': teacherId,
      'classId': classId,
    };
  }

  factory SubjectItem.fromMap(Map<String, dynamic> map) {
    return SubjectItem(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      teacherId: (map['teacherId'] ?? '').toString(),
      classId: (map['classId'] ?? '').toString(),
    );
  }
}
