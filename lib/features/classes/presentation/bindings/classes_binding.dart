import 'package:get/get.dart';

import '../controllers/classes_controller.dart';

class ClassesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ClassesController>()) {
      Get.lazyPut<ClassesController>(ClassesController.new);
    }
  }
}
