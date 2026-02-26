import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/subject_item.dart';

class SubjectsController extends GetxController {
  SubjectsController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final subjects = <SubjectItem>[].obs;
  final isLoading = true.obs;
  final isLocalMode = true.obs;
  final syncError = RxnString();
  String? _uid;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();

    isLoading.value = true;
    isLocalMode.value = false;
    syncError.value = null;

    var teachersReady = false;
    var classesReady = false;
    var modulesReady = false;

    void finishLoad() {
      if (teachersReady && classesReady && modulesReady) {
        isLoading.value = false;
      }
    }

    _teachersSub = _service.watchTeachers(uid).listen((data) {
      teachers.assignAll(data);
      teachersReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

    _classesSub = _service.watchClasses(uid).listen((data) {
      classes.assignAll(data);
      classesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

    _modulesSub = _service.watchModules(uid).listen((data) {
      final raw = data['subjects'];
      if (raw is List) {
        subjects.assignAll(
          raw
              .map(
                (item) =>
                    SubjectItem.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
        );
      } else {
        subjects.clear();
      }
      modulesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));
  }

  void addSubject({
    required String name,
    required String code,
    required String teacherId,
    required String classId,
  }) {
    subjects.assignAll([
      ...subjects,
      SubjectItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        code: code,
        teacherId: teacherId,
        classId: classId,
      ),
    ]);
    unawaited(_persistSubjects());
  }

  void updateSubject({
    required String id,
    required String name,
    required String code,
    required String teacherId,
    required String classId,
  }) {
    subjects.assignAll(
      subjects.map((item) {
        if (item.id != id) return item;
        return item.copyWith(
          name: name,
          code: code,
          teacherId: teacherId,
          classId: classId,
        );
      }).toList(),
    );
    unawaited(_persistSubjects());
  }

  void deleteSubject(String id) {
    subjects.assignAll(subjects.where((item) => item.id != id).toList());
    unawaited(_persistSubjects());
  }

  Future<void> retrySync(String uid) async {
    _uid = null;
    bind(uid);
  }

  Future<void> _persistSubjects() async {
    final uid = _uid;
    if (uid == null || isLocalMode.value) return;
    try {
      await _service.saveModules(
        uid: uid,
        modules: {'subjects': subjects.map((item) => item.toMap()).toList()},
      );
    } catch (error) {
      isLocalMode.value = true;
      syncError.value = error.toString();
    }
  }

  void _syncFailure(String error) {
    isLoading.value = false;
    isLocalMode.value = true;
    syncError.value = error;
  }

  @override
  void onClose() {
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
    super.onClose();
  }
}
