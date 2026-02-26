import 'package:get/get.dart';

import '../controllers/exams_controller.dart';

class ExamsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ExamsController>()) {
      Get.lazyPut<ExamsController>(ExamsController.new);
    }
  }
}
