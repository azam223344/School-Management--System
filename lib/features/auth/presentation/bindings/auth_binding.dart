import 'package:get/get.dart';

import '../controllers/auth_flow_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthFlowController>()) {
      Get.lazyPut<AuthFlowController>(AuthFlowController.new);
    }
  }
}
