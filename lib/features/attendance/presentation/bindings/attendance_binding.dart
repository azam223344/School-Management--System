import 'package:get/get.dart';

import '../controllers/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AttendanceController>()) {
      Get.lazyPut<AttendanceController>(AttendanceController.new);
    }
  }
}
