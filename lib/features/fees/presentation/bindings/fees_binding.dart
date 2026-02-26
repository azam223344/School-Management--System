import 'package:get/get.dart';

import '../controllers/fees_controller.dart';

class FeesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FeesController>()) {
      Get.lazyPut<FeesController>(FeesController.new);
    }
  }
}
