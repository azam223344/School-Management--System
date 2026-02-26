import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'config/dependency_injection/app_providers.dart';
import 'core/constants/app_constants.dart';
import 'config/routes/route_constants.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'config/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const SchoolManagementProApp());
}

class SchoolManagementProApp extends StatelessWidget {
  const SchoolManagementProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.all,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            final width = MediaQuery.sizeOf(context).width;
            if (width >= 360) return child ?? const SizedBox.shrink();

            final theme = Theme.of(context);
            final inputTheme = theme.inputDecorationTheme;
            return Theme(
              data: theme.copyWith(
                inputDecorationTheme: inputTheme.copyWith(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: RouteConstants.splash,
          getPages: AppRoutes.pages,
          unknownRoute: AppRoutes.unknownRoute,
        ),
      ),
    );
  }
}
