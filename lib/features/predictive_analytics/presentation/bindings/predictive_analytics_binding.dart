import 'package:get/get.dart';

import '../controllers/predictive_analytics_controller.dart';

class PredictiveAnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PredictiveAnalyticsController>()) {
      Get.lazyPut<PredictiveAnalyticsController>(
        PredictiveAnalyticsController.new,
      );
    }
  }
}
