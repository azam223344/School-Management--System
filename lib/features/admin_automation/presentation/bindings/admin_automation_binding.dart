import 'package:get/get.dart';

import '../controllers/admin_automation_controller.dart';

class AdminAutomationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdminAutomationController>()) {
      Get.lazyPut<AdminAutomationController>(AdminAutomationController.new);
    }
  }
}
