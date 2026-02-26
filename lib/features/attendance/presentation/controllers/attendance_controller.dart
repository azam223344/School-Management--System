import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/attendance_record.dart';

class AttendanceController extends GetxController {
  AttendanceController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final students = <SchoolStudent>[].obs;
  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final records = <AttendanceRecord>[].obs;
  final isLoading = true.obs;
  final isLocalMode = true.obs;
  final syncError = RxnString();
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _studentsSub?.cancel();
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();

    isLoading.value = true;
    isLocalMode.value = false;
    syncError.value = null;

    var teachersReady = false;
    var studentsReady = false;
    var classesReady = false;
    var modulesReady = false;

    void finishLoad() {
      if (teachersReady && studentsReady && classesReady && modulesReady) {
        isLoading.value = false;
      }
    }

    _teachersSub = _service.watchTeachers(uid).listen((data) {
      teachers.assignAll(data);
      teachersReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

    _studentsSub = _service.watchStudents(uid).listen((data) {
      students.assignAll(data);
      studentsReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

    _classesSub = _service.watchClasses(uid).listen((data) {
      classes.assignAll(data);
      classesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

    _modulesSub = _service.watchModules(uid).listen((data) {
      final raw = data['attendanceRecords'];
      if (raw is List) {
        records.assignAll(
          raw
              .map(
                (item) => AttendanceRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
        );
      } else {
        records.clear();
      }
      modulesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));
  }

  void upsertRecord({
    required String classId,
    required String studentId,
    required DateTime date,
    required bool present,
  }) {
    final index = records.indexWhere((r) {
      return r.classId == classId &&
          r.studentId == studentId &&
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    });
    if (index == -1) {
      records.assignAll([
        ...records,
        AttendanceRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          classId: classId,
          studentId: studentId,
          date: DateTime(date.year, date.month, date.day),
          present: present,
        ),
      ]);
      return;
    }
    final next = [...records];
    next[index] = next[index].copyWith(present: present);
    records.assignAll(next);
  }

  Future<void> saveAttendance() async {
    final uid = _uid;
    if (uid == null || isLocalMode.value) return;
    try {
      await _service.saveModules(
        uid: uid,
        modules: {'attendanceRecords': records.map((r) => r.toMap()).toList()},
      );
    } catch (error) {
      isLocalMode.value = true;
      syncError.value = error.toString();
    }
  }

  Future<void> retrySync(String uid) async {
    _uid = null;
    bind(uid);
  }

  @override
  void onClose() {
    _studentsSub?.cancel();
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
    super.onClose();
  }

  void _syncFailure(String error) {
    isLoading.value = false;
    isLocalMode.value = true;
    syncError.value = error;
  }
}
