import 'package:get/get.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';

class SettingsController extends GetxController {
  final AuthProvider auth = Get.find<AuthProvider>();
  final ThemeProvider theme = Get.find<ThemeProvider>();
}
