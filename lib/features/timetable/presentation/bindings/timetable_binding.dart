import 'package:get/get.dart';

import '../controllers/timetable_controller.dart';

class TimetableBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TimetableController>()) {
      Get.lazyPut<TimetableController>(TimetableController.new);
    }
  }
}
