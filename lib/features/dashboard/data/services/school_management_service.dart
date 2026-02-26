import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';

class SchoolManagementService {
  CollectionReference<Map<String, dynamic>> _studentsRef(String uid) {
    return FirestoreService.usersRef().doc(uid).collection('students');
  }

  CollectionReference<Map<String, dynamic>> _teachersRef(String uid) {
    return FirestoreService.usersRef().doc(uid).collection('teachers');
  }

  CollectionReference<Map<String, dynamic>> _classesRef(String uid) {
    return FirestoreService.usersRef().doc(uid).collection('classes');
  }

  DocumentReference<Map<String, dynamic>> _modulesDoc(String uid) {
    return FirestoreService.usersRef()
        .doc(uid)
        .collection('schoolModules')
        .doc('main');
  }

  Stream<List<SchoolStudent>> watchStudents(String uid) {
    return _studentsRef(uid).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(SchoolStudent.fromDoc).toList();
    });
  }

  Stream<List<SchoolTeacher>> watchTeachers(String uid) {
    return _teachersRef(uid).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(SchoolTeacher.fromDoc).toList();
    });
  }

  Stream<List<SchoolClass>> watchClasses(String uid) {
    return _classesRef(uid).orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map(SchoolClass.fromDoc).toList();
    });
  }

  Future<void> createStudent({
    required String uid,
    required String name,
    required String rollNumber,
    required String grade,
    required String age,
    required String phoneNumber,
    required String parentName,
    required String parentIdentityNumber,
    required String studentIdentityNumber,
    required String photoUrl,
    required String notes,
  }) async {
    final ref = _studentsRef(uid).doc();
    await ref.set({
      'id': ref.id,
      'name': name,
      'rollNumber': rollNumber,
      'grade': grade,
      'age': age,
      'phoneNumber': phoneNumber,
      'parentName': parentName,
      'parentIdentityNumber': parentIdentityNumber,
      'studentIdentityNumber': studentIdentityNumber,
      'photoUrl': photoUrl,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudent({
    required String uid,
    required String id,
    required String name,
    required String rollNumber,
    required String grade,
    required String age,
    required String phoneNumber,
    required String parentName,
    required String parentIdentityNumber,
    required String studentIdentityNumber,
    required String photoUrl,
    required String notes,
  }) async {
    await _studentsRef(uid).doc(id).set({
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'grade': grade,
      'age': age,
      'phoneNumber': phoneNumber,
      'parentName': parentName,
      'parentIdentityNumber': parentIdentityNumber,
      'studentIdentityNumber': studentIdentityNumber,
      'photoUrl': photoUrl,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteStudent({
    required String uid,
    required String studentId,
  }) async {
    final batch = FirestoreService.instance.batch();
    batch.delete(_studentsRef(uid).doc(studentId));

    final classes = await _classesRef(uid).get();
    for (final classDoc in classes.docs) {
      final schoolClass = SchoolClass.fromDoc(classDoc);
      if (!schoolClass.studentIds.contains(studentId)) {
        continue;
      }

      final updatedStudentIds = schoolClass.studentIds
          .where((id) => id != studentId)
          .toList();
      final updatedAttendance = Map<String, bool>.from(schoolClass.attendance)
        ..remove(studentId);
      batch.update(classDoc.reference, {
        'studentIds': updatedStudentIds,
        'attendance': updatedAttendance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> createTeacher({
    required String uid,
    required String name,
    required String subject,
    required String email,
    required String age,
    required String qualifications,
    required String phoneNumber,
    required String identityNumber,
    required String address,
    required String notes,
  }) async {
    final ref = _teachersRef(uid).doc();
    await ref.set({
      'id': ref.id,
      'name': name,
      'subject': subject,
      'email': email,
      'age': age,
      'qualifications': qualifications,
      'phoneNumber': phoneNumber,
      'identityNumber': identityNumber,
      'address': address,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTeacher({
    required String uid,
    required String id,
    required String name,
    required String subject,
    required String email,
    required String age,
    required String qualifications,
    required String phoneNumber,
    required String identityNumber,
    required String address,
    required String notes,
  }) async {
    await _teachersRef(uid).doc(id).set({
      'id': id,
      'name': name,
      'subject': subject,
      'email': email,
      'age': age,
      'qualifications': qualifications,
      'phoneNumber': phoneNumber,
      'identityNumber': identityNumber,
      'address': address,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteTeacher({
    required String uid,
    required String teacherId,
  }) async {
    final batch = FirestoreService.instance.batch();
    batch.delete(_teachersRef(uid).doc(teacherId));

    final classes = await _classesRef(
      uid,
    ).where('teacherId', isEqualTo: teacherId).get();
    for (final classDoc in classes.docs) {
      batch.update(classDoc.reference, {
        'teacherId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> createClass({
    required String uid,
    required String name,
    required String? teacherId,
    required List<String> studentIds,
  }) async {
    final ref = _classesRef(uid).doc();
    await ref.set({
      'id': ref.id,
      'name': name,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'attendance': {for (final studentId in studentIds) studentId: false},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateClass({
    required String uid,
    required String id,
    required String name,
    required String? teacherId,
    required List<String> studentIds,
    required Map<String, bool> attendance,
  }) async {
    await _classesRef(uid).doc(id).set({
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'attendance': attendance,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteClass({
    required String uid,
    required String classId,
  }) async {
    await _classesRef(uid).doc(classId).delete();
  }

  Future<void> markAttendance({
    required String uid,
    required String classId,
    required Map<String, bool> attendance,
  }) async {
    await _classesRef(uid).doc(classId).update({
      'attendance': attendance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>> watchModules(String uid) {
    return _modulesDoc(uid).snapshots().map((snapshot) {
      return snapshot.data() ?? <String, dynamic>{};
    });
  }

  Future<void> saveModules({
    required String uid,
    required Map<String, dynamic> modules,
  }) async {
    await _modulesDoc(uid).set({
      ...modules,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<UserAccessProfile>> watchUserProfiles() {
    return FirestoreService.usersRef().snapshots().map((snapshot) {
      final items = snapshot.docs.map(UserAccessProfile.fromDoc).toList();
      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return items;
    });
  }

  Future<void> updateUserAccess({
    required String uid,
    required AppRole role,
    required List<String> linkedStudentIds,
    String? teacherId,
  }) async {
    await FirestoreService.usersRef().doc(uid).set({
      'role': role.value,
      'linkedStudentIds': linkedStudentIds,
      'teacherId': teacherId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class SchoolStudent {
  const SchoolStudent({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.grade,
    this.age = '',
    this.phoneNumber = '',
    this.parentName = '',
    this.parentIdentityNumber = '',
    this.studentIdentityNumber = '',
    this.photoUrl = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final String rollNumber;
  final String grade;
  final String age;
  final String phoneNumber;
  final String parentName;
  final String parentIdentityNumber;
  final String studentIdentityNumber;
  final String photoUrl;
  final String notes;

  factory SchoolStudent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SchoolStudent(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      rollNumber: (data['rollNumber'] as String?) ?? '',
      grade: (data['grade'] as String?) ?? '',
      age: (data['age'] as String?) ?? '',
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      parentName: (data['parentName'] as String?) ?? '',
      parentIdentityNumber: (data['parentIdentityNumber'] as String?) ?? '',
      studentIdentityNumber: (data['studentIdentityNumber'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
    );
  }
}

class SchoolTeacher {
  const SchoolTeacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    this.age = '',
    this.qualifications = '',
    this.phoneNumber = '',
    this.identityNumber = '',
    this.address = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final String subject;
  final String email;
  final String age;
  final String qualifications;
  final String phoneNumber;
  final String identityNumber;
  final String address;
  final String notes;

  factory SchoolTeacher.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SchoolTeacher(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      subject: (data['subject'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      age: (data['age'] as String?) ?? '',
      qualifications: (data['qualifications'] as String?) ?? '',
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      identityNumber: (data['identityNumber'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
    );
  }
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.studentIds,
    required this.attendance,
  });

  final String id;
  final String name;
  final String? teacherId;
  final List<String> studentIds;
  final Map<String, bool> attendance;

  factory SchoolClass.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final attendanceData = (data['attendance'] as Map<String, dynamic>?) ?? {};
    return SchoolClass(
      id: (data['id'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      teacherId: data['teacherId'] as String?,
      studentIds: ((data['studentIds'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      attendance: attendanceData.map((key, value) {
        return MapEntry(key, value == true);
      }),
    );
  }
}

class UserAccessProfile {
  const UserAccessProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.linkedStudentIds,
    required this.teacherId,
  });

  final String uid;
  final String name;
  final String email;
  final AppRole role;
  final List<String> linkedStudentIds;
  final String? teacherId;

  factory UserAccessProfile.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserAccessProfile(
      uid: (data['uid'] as String?) ?? doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: appRoleFromString((data['role'] as String?) ?? 'admin'),
      linkedStudentIds: ((data['linkedStudentIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      teacherId: data['teacherId'] as String?,
    );
  }
}
