enum FeeTargetType { student, teacher, schoolClass }

class FeeItem {
  const FeeItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.targetType,
    required this.targetId,
    required this.paid,
  });

  final String id;
  final String title;
  final String amount;
  final String dueDate;
  final FeeTargetType targetType;
  final String targetId;
  final bool paid;

  FeeItem copyWith({
    String? title,
    String? amount,
    String? dueDate,
    FeeTargetType? targetType,
    String? targetId,
    bool? paid,
  }) {
    return FeeItem(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      paid: paid ?? this.paid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate,
      'targetType': _targetTypeToString(targetType),
      'targetId': targetId,
      'paid': paid,
    };
  }

  static String _targetTypeToString(FeeTargetType type) {
    switch (type) {
      case FeeTargetType.student:
        return 'student';
      case FeeTargetType.teacher:
        return 'teacher';
      case FeeTargetType.schoolClass:
        return 'schoolClass';
    }
  }

  static FeeTargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return FeeTargetType.teacher;
      case 'schoolClass':
        return FeeTargetType.schoolClass;
      case 'student':
      default:
        return FeeTargetType.student;
    }
  }

  factory FeeItem.fromMap(Map<String, dynamic> map) {
    return FeeItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      amount: (map['amount'] ?? '').toString(),
      dueDate: (map['dueDate'] ?? '').toString(),
      targetType: _targetTypeFromString((map['targetType'] ?? '').toString()),
      targetId: (map['targetId'] ?? '').toString(),
      paid: map['paid'] == true,
    );
  }
}
