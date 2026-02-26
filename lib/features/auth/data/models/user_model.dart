import 'package:firebase_auth/firebase_auth.dart';

enum AppRole { admin, teacher, parent, student }

extension AppRoleX on AppRole {
  String get value {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.teacher:
        return 'teacher';
      case AppRole.parent:
        return 'parent';
      case AppRole.student:
        return 'student';
    }
  }
}

AppRole appRoleFromString(String? raw) {
  switch (raw) {
    case 'teacher':
      return AppRole.teacher;
    case 'parent':
      return AppRole.parent;
    case 'student':
      return AppRole.student;
    case 'admin':
    default:
      return AppRole.admin;
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
    required this.providerIds,
    required this.role,
    required this.linkedStudentIds,
    required this.teacherId,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final List<String> providerIds;
  final AppRole role;
  final List<String> linkedStudentIds;
  final String? teacherId;

  bool get isPasswordUser => providerIds.contains('password');

  factory UserModel.fromFirebase(User user, {Map<String, dynamic>? profile}) {
    final profileData = profile ?? const <String, dynamic>{};
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      providerIds: user.providerData.map((e) => e.providerId).toList(),
      role: appRoleFromString(profileData['role']?.toString()),
      linkedStudentIds: ((profileData['linkedStudentIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      teacherId: profileData['teacherId']?.toString(),
    );
  }
}
