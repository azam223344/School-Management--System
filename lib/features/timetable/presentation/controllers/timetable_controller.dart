import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/timetable_item.dart';

class TimetableController extends GetxController {
  TimetableController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final items = <TimetableItem>[].obs;
  final isLoading = true.obs;
  final isLocalMode = true.obs;
  final syncError = RxnString();
  final search = ''.obs;
  String? _uid;

  List<TimetableItem> get filtered {
    final q = search.value.trim().toLowerCase();
    return items.where((item) {
      if (q.isEmpty) return true;
      return item.day.toLowerCase().contains(q) ||
          item.time.toLowerCase().contains(q) ||
          item.subject.toLowerCase().contains(q);
    }).toList();
  }

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
      final raw = data['timetable'];
      if (raw is List) {
        items.assignAll(
          raw
              .map(
                (e) =>
                    TimetableItem.fromMap(Map<String, dynamic>.from(e as Map)),
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

  void updateSearch(String value) {
    search.value = value;
  }

  void addItem(TimetableItem item) {
    items.assignAll([...items, item]);
    unawaited(_persist());
  }

  void updateItem(TimetableItem existing) {
    items.assignAll(
      items.map((item) => item.id == existing.id ? existing : item),
    );
    unawaited(_persist());
  }

  void deleteItem(String id) {
    items.assignAll(items.where((e) => e.id != id));
    unawaited(_persist());
  }

  String teacherName(String id) {
    final item = teachers.where((e) => e.id == id).firstOrNull;
    return item?.name ?? 'Teacher';
  }

  String className(String id) {
    final item = classes.where((e) => e.id == id).firstOrNull;
    return item?.name ?? 'Class';
  }

  Future<void> retrySync(String uid) async {
    _uid = null;
    bind(uid);
  }

  @override
  void onClose() {
    _teachersSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
    super.onClose();
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null || isLocalMode.value) return;
    try {
      await _service.saveModules(
        uid: uid,
        modules: {'timetable': items.map((e) => e.toMap()).toList()},
      );
    } catch (error) {
      isLocalMode.value = true;
      syncError.value = error.toString();
    }
  }

  void _syncFailure(String message) {
    isLoading.value = false;
    isLocalMode.value = true;
    syncError.value = message;
  }
}
