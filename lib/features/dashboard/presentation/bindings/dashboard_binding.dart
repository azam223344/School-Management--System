import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DashboardController>()) {
      Get.lazyPut<DashboardController>(DashboardController.new);
    }
  }
}
