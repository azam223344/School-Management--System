enum TransportTargetType { student, teacher, schoolClass }

class TransportItem {
  const TransportItem({
    required this.id,
    required this.routeName,
    required this.vehicleNo,
    required this.driver,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String routeName;
  final String vehicleNo;
  final String driver;
  final TransportTargetType targetType;
  final String targetId;

  TransportItem copyWith({
    String? routeName,
    String? vehicleNo,
    String? driver,
    TransportTargetType? targetType,
    String? targetId,
  }) {
    return TransportItem(
      id: id,
      routeName: routeName ?? this.routeName,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      driver: driver ?? this.driver,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeName': routeName,
      'vehicleNo': vehicleNo,
      'driver': driver,
      'targetType': _targetTypeToString(targetType),
      'targetId': targetId,
    };
  }

  static String _targetTypeToString(TransportTargetType type) {
    switch (type) {
      case TransportTargetType.student:
        return 'student';
      case TransportTargetType.teacher:
        return 'teacher';
      case TransportTargetType.schoolClass:
        return 'schoolClass';
    }
  }

  static TransportTargetType _targetTypeFromString(String value) {
    switch (value) {
      case 'teacher':
        return TransportTargetType.teacher;
      case 'schoolClass':
        return TransportTargetType.schoolClass;
      case 'student':
      default:
        return TransportTargetType.student;
    }
  }

  factory TransportItem.fromMap(Map<String, dynamic> map) {
    return TransportItem(
      id: (map['id'] ?? '').toString(),
      routeName: (map['routeName'] ?? '').toString(),
      vehicleNo: (map['vehicleNo'] ?? '').toString(),
      driver: (map['driver'] ?? '').toString(),
      targetType: _targetTypeFromString((map['targetType'] ?? '').toString()),
      targetId: (map['targetId'] ?? '').toString(),
    );
  }
}
