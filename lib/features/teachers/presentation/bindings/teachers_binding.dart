import 'package:get/get.dart';

import '../controllers/teachers_controller.dart';

class TeachersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TeachersController>()) {
      Get.lazyPut<TeachersController>(TeachersController.new);
    }
  }
}
