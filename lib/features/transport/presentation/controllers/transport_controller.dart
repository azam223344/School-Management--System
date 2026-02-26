import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/transport_item.dart';

class TransportController extends GetxController {
  TransportController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final students = <SchoolStudent>[].obs;
  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final items = <TransportItem>[].obs;
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
      final raw = data['transport'];
      if (raw is List) {
        items.assignAll(
          raw
              .map(
                (item) => TransportItem.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
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
    required String routeName,
    required String vehicleNo,
    required String driver,
    required TransportTargetType targetType,
    required String targetId,
  }) {
    items.assignAll([
      ...items,
      TransportItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        routeName: routeName,
        vehicleNo: vehicleNo,
        driver: driver,
        targetType: targetType,
        targetId: targetId,
      ),
    ]);
    unawaited(_persist());
  }

  void updateItem({
    required String id,
    required String routeName,
    required String vehicleNo,
    required String driver,
    required TransportTargetType targetType,
    required String targetId,
  }) {
    items.assignAll(
      items.map((item) {
        if (item.id != id) return item;
        return item.copyWith(
          routeName: routeName,
          vehicleNo: vehicleNo,
          driver: driver,
          targetType: targetType,
          targetId: targetId,
        );
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
        modules: {'transport': items.map((e) => e.toMap()).toList()},
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
