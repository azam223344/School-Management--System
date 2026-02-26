import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/fee_item.dart';

class FeesController extends GetxController {
  FeesController({SchoolManagementService? service})
    : _service = service ?? SchoolManagementService();

  final SchoolManagementService _service;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolTeacher>>? _teachersSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  final students = <SchoolStudent>[].obs;
  final teachers = <SchoolTeacher>[].obs;
  final classes = <SchoolClass>[].obs;
  final fees = <FeeItem>[].obs;
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
      final raw = data['fees'];
      if (raw is List) {
        fees.assignAll(
          raw
              .map(
                (item) =>
                    FeeItem.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
        );
      } else {
        fees.clear();
      }
      modulesReady = true;
      finishLoad();
    }, onError: (e) => _syncFailure(e.toString()));
  }

  void addFee({
    required String title,
    required String amount,
    required String dueDate,
    required FeeTargetType targetType,
    required String targetId,
  }) {
    fees.assignAll([
      ...fees,
      FeeItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        dueDate: dueDate,
        targetType: targetType,
        targetId: targetId,
        paid: false,
      ),
    ]);
    unawaited(_persistFees());
  }

  void updateFee({
    required String id,
    required String title,
    required String amount,
    required String dueDate,
    required FeeTargetType targetType,
    required String targetId,
  }) {
    fees.assignAll(
      fees.map((item) {
        if (item.id != id) return item;
        return item.copyWith(
          title: title,
          amount: amount,
          dueDate: dueDate,
          targetType: targetType,
          targetId: targetId,
        );
      }).toList(),
    );
    unawaited(_persistFees());
  }

  void togglePaid(String id) {
    fees.assignAll(
      fees.map((item) {
        if (item.id != id) return item;
        return item.copyWith(paid: !item.paid);
      }).toList(),
    );
    unawaited(_persistFees());
  }

  void deleteFee(String id) {
    fees.assignAll(fees.where((item) => item.id != id).toList());
    unawaited(_persistFees());
  }

  Future<void> retrySync(String uid) async {
    _uid = null;
    bind(uid);
  }

  Future<void> _persistFees() async {
    final uid = _uid;
    if (uid == null || isLocalMode.value) return;
    try {
      await _service.saveModules(
        uid: uid,
        modules: {'fees': fees.map((item) => item.toMap()).toList()},
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
