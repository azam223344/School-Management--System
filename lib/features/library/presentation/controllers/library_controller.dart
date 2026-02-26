import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/library_item.dart';

class LibraryController extends GetxController {
  LibraryController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final students = <SchoolStudent>[].obs;
  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final items = <LibraryItem>[].obs;
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

    var studentsReady = false;
    var teachersReady = false;
    var classesReady = false;
    var modulesReady = false;

    void finishLoad() {
      if (studentsReady && teachersReady && classesReady && modulesReady) {
        isLoading.value = false;
      }
    }

    _studentsSub = _service.watchStudents(uid).listen((data) {
      students.assignAll(data);
      studentsReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));

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
      final raw = data['library'];
      if (raw is List) {
        items.assignAll(
          raw
              .map(
                (item) =>
                    LibraryItem.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
        );
      } else {
        items.clear();
      }
      modulesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));
  }

  void addItem({
    required String bookName,
    required String dueDate,
    required LibraryTargetType targetType,
    required String targetId,
  }) {
    items.assignAll([
      ...items,
      LibraryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        bookName: bookName,
        dueDate: dueDate,
        targetType: targetType,
        targetId: targetId,
        returned: false,
      ),
    ]);
    unawaited(_persist());
  }

  void updateItem({
    required String id,
    required String bookName,
    required String dueDate,
    required LibraryTargetType targetType,
    required String targetId,
  }) {
    items.assignAll(
      items.map((item) {
        if (item.id != id) return item;
        return item.copyWith(
          bookName: bookName,
          dueDate: dueDate,
          targetType: targetType,
          targetId: targetId,
        );
      }).toList(),
    );
    unawaited(_persist());
  }

  void toggleReturned(String id) {
    items.assignAll(
      items.map((item) {
        if (item.id != id) return item;
        return item.copyWith(returned: !item.returned);
      }).toList(),
    );
    unawaited(_persist());
  }

  void deleteItem(String id) {
    items.assignAll(items.where((item) => item.id != id).toList());
    unawaited(_persist());
  }

  Future<void> retrySync(String uid) async {
    _uid = null;
    bind(uid);
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null || isLocalMode.value) return;
    try {
      await _service.saveModules(
        uid: uid,
        modules: {'library': items.map((item) => item.toMap()).toList()},
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
    _studentsSub?.cancel();
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
    super.onClose();
  }
}
