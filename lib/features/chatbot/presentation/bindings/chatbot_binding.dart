import 'package:get/get.dart';

import '../controllers/chatbot_controller.dart';

class ChatbotBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ChatbotController>()) {
      Get.lazyPut<ChatbotController>(ChatbotController.new);
    }
  }
}
