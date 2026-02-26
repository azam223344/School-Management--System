import 'dart:async';

import 'package:get/get.dart';

import '../../../dashboard/data/services/school_management_service.dart';
import '../../data/models/admin_automation_recommendation.dart';
import '../../data/services/admin_automation_service.dart';

class AdminAutomationController extends GetxController {
  AdminAutomationController({
    SchoolManagementService? schoolService,
    AdminAutomationService? automationService,
  }) : _schoolService = schoolService ?? SchoolManagementService(),
       _automationService = automationService ?? AdminAutomationService();

  final SchoolManagementService _schoolService;
  final AdminAutomationService _automationService;

  StreamSubscription<List<SchoolClass>>? _classesSub;
  StreamSubscription<Map<String, dynamic>>? _modulesSub;

  List<SchoolClass> _classes = const [];
  Map<String, dynamic> _modules = const {};
  bool _classesReady = false;
  bool _modulesReady = false;

  final isLoading = true.obs;
  final isLocalMode = true.obs;
  final syncError = RxnString();
  final score = 0.0.obs;
  final recommendations = <AdminAutomationRecommendation>[].obs;

  void bind(String uid) {
    _disposeStreams();
    isLoading.value = true;
    isLocalMode.value = false;
    syncError.value = null;
    _classesReady = false;
    _modulesReady = false;

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

  @override
  void onClose() {
    _disposeStreams();
    super.onClose();
  }

  void _disposeStreams() {
    _classesSub?.cancel();
    _modulesSub?.cancel();
  }

  void _onError(Object error) {
    isLoading.value = false;
    isLocalMode.value = true;
    syncError.value = error.toString();
  }

  void _recompute() {
    recommendations.assignAll(
      _automationService.buildRecommendations(
        classes: _classes,
        modules: _modules,
      ),
    );
    score.value = _automationService.automationScore(
      classes: _classes,
      modules: _modules,
    );
    isLoading.value = !(_classesReady && _modulesReady);
  }
}
