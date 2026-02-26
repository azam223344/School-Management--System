import 'package:get/get.dart';

import '../controllers/subjects_controller.dart';

class SubjectsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubjectsController>()) {
      Get.lazyPut<SubjectsController>(SubjectsController.new);
    }
  }
}
