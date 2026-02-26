import 'package:get/get.dart';

import '../controllers/transport_controller.dart';

class TransportBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TransportController>()) {
      Get.lazyPut<TransportController>(TransportController.new);
    }
  }
}
