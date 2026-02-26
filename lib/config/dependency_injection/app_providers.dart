import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/theme/theme_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppProviders {
  static final AuthProvider authProvider = AuthProvider();
  static final ThemeProvider themeProvider = ThemeProvider();
  static bool _registeredInGet = false;

  static List<SingleChildWidget> get all {
    if (!_registeredInGet) {
      Get.put<AuthProvider>(authProvider, permanent: true);
      Get.put<ThemeProvider>(themeProvider, permanent: true);
      _registeredInGet = true;
    }
    return [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: themeProvider),
    ];
  }
}
