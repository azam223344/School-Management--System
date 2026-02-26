import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/student_risk_prediction.dart';
import '../../data/services/predictive_analytics_service.dart';

class PredictiveAnalyticsController extends GetxController {
  PredictiveAnalyticsController({
    SchoolManagementService? schoolService,
    PredictiveAnalyticsService? analyticsService,
  }) : _schoolService = schoolService ?? SchoolManagementService(),
       _analyticsService = analyticsService ?? PredictiveAnalyticsService();

  final SchoolManagementService _schoolService;
  final PredictiveAnalyticsService _analyticsService;

  StreamSubscription<List<SchoolStudent>>? _studentsSub;
  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  List<SchoolStudent> _students = const [];
  List<SchoolClass> _classes = const [];
  Map<String, dynamic> _modules = const {};

  bool _studentsReady = false;
  bool _classesReady = false;
  bool _modulesReady = false;

  final isLoading = true.obs;
  final isLocalMode = true.obs;
  final syncError = RxnString();
  final predictions = <StudentRiskPrediction>[].obs;

  void bind(String uid) {
    _disposeStreams();
    isLoading.value = true;
    isLocalMode.value = false;
    syncError.value = null;
    _studentsReady = false;
    _classesReady = false;
    _modulesReady = false;

    _studentsSub = _schoolService.watchStudents(uid).listen((value) {
      _students = value;
      _studentsReady = true;
      _recompute();
    }, onError: _onError);

    _classesSub = _schoolService.watchClasses(uid).listen((value) {
      _classes = value;
      _classesReady = true;
      _recompute();
    }, onError: _onError);

    _modulesSub = _schoolService.watchModules(uid).listen((value) {
      _modules = value;
      _modulesReady = true;
      _recompute();
    }, onError: _onError);
  }

  int get highRiskCount =>
      predictions.where((e) => e.riskBand == 'High').length;
  int get mediumRiskCount =>
      predictions.where((e) => e.riskBand == 'Medium').length;
  int get lowRiskCount => predictions.where((e) => e.riskBand == 'Low').length;

  @override
  void onClose() {
    _disposeStreams();
    super.onClose();
  }

  void _disposeStreams() {
    _studentsSub?.cancel();
    _classesSub?.cancel();
    _modulesSub?.cancel();
  }

  void _onError(Object error) {
    isLoading.value = false;
    isLocalMode.value = true;
    syncError.value = error.toString();
  }

  void _recompute() {
    predictions.assignAll(
      _analyticsService.generatePredictions(
        students: _students,
        classes: _classes,
        modules: _modules,
      ),
    );
    isLoading.value = !(_studentsReady && _classesReady && _modulesReady);
  }
}
