import 'package:get/get.dart';

import '../controllers/students_controller.dart';

class StudentsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StudentsController>()) {
      Get.lazyPut<StudentsController>(StudentsController.new);
    }
  }
}
