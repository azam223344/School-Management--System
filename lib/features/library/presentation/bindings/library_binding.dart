import 'package:get/get.dart';

import '../controllers/library_controller.dart';

class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LibraryController>()) {
      Get.lazyPut<LibraryController>(LibraryController.new);
    }
  }
}
