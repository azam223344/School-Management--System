import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../core/utils/role_permissions.dart';
import '../../core/widgets/route_role_guard.dart';
import '../../features/admin_automation/presentation/bindings/admin_automation_binding.dart';
import '../../features/admin_automation/presentation/screens/admin_automation_screen.dart';
import '../../features/attendance/presentation/bindings/attendance_binding.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/chatbot/presentation/bindings/chatbot_binding.dart';
import '../../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/classes/presentation/bindings/classes_binding.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/dashboard/presentation/bindings/dashboard_binding.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/exams/presentation/bindings/exams_binding.dart';
import '../../features/exams/presentation/screens/exams_screen.dart';
import '../../features/fees/presentation/bindings/fees_binding.dart';
import '../../features/fees/presentation/screens/fees_screen.dart';
import '../../features/library/presentation/bindings/library_binding.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/notifications/presentation/bindings/notifications_binding.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/predictive_analytics/presentation/bindings/predictive_analytics_binding.dart';
import '../../features/predictive_analytics/presentation/screens/predictive_analytics_screen.dart';
import '../../features/results/presentation/bindings/results_binding.dart';
import '../../features/results/presentation/screens/results_screen.dart';
import '../../features/settings/presentation/screens/change_email_screen.dart';
import '../../features/settings/presentation/screens/change_password_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/role_management_screen.dart';
import '../../features/settings/presentation/bindings/settings_binding.dart';
import '../../features/students/presentation/bindings/students_binding.dart';
import '../../features/students/presentation/screens/students_screen.dart';
import '../../features/subjects/presentation/bindings/subjects_binding.dart';
import '../../features/subjects/presentation/screens/subjects_screen.dart';
import '../../features/teachers/presentation/bindings/teachers_binding.dart';
import '../../features/teachers/presentation/screens/teachers_screen.dart';
import '../../features/timetable/presentation/bindings/timetable_binding.dart';
import '../../features/timetable/presentation/screens/timetable_screen.dart';
import '../../features/transport/presentation/bindings/transport_binding.dart';
import '../../features/transport/presentation/screens/transport_screen.dart';
import 'route_constants.dart';

class AppRoutes {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(
      name: RouteConstants.splash,
      binding: AuthBinding(),
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: RouteConstants.login,
      binding: AuthBinding(),
      page: () => const _PublicOnly(child: LoginScreen()),
    ),
    GetPage(
      name: RouteConstants.register,
      binding: AuthBinding(),
      page: () => const _PublicOnly(child: RegisterScreen()),
    ),
    GetPage(
      name: RouteConstants.forgotPassword,
      binding: AuthBinding(),
      page: () => const _PublicOnly(child: ForgotPasswordScreen()),
    ),
    GetPage(
      name: RouteConstants.verifyEmail,
      binding: AuthBinding(),
      page: () =>
          const _Protected(allowUnverified: true, child: VerifyEmailScreen()),
    ),
    GetPage(
      name: RouteConstants.home,
      binding: DashboardBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.home],
        child: HomeScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.profile,
      binding: SettingsBinding(),
      page: () => const _Protected(child: ProfileScreen()),
    ),
    GetPage(
      name: RouteConstants.roleManagement,
      binding: SettingsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.roleManagement],
        child: RoleManagementScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.students,
      binding: StudentsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.students],
        child: StudentsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.teachers,
      binding: TeachersBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.teachers],
        child: TeachersScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.classes,
      binding: ClassesBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.classes],
        child: ClassesScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.subjects,
      binding: SubjectsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.subjects],
        child: const SubjectsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.attendance,
      binding: AttendanceBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.attendance],
        child: const AttendanceScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.exams,
      binding: ExamsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.exams],
        child: const ExamsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.results,
      binding: ResultsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.results],
        child: const ResultsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.fees,
      binding: FeesBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.fees],
        child: const FeesScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.notifications,
      binding: NotificationsBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.notifications],
        child: const NotificationsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.timetable,
      binding: TimetableBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.timetable],
        child: const TimetableScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.library,
      binding: LibraryBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.library],
        child: const LibraryScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.transport,
      binding: TransportBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.transport],
        child: const TransportScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.chatbot,
      binding: ChatbotBinding(),
      page: () {
        final args = Get.arguments;
        final moduleContext = args is Map ? args['module']?.toString() : null;
        final initialPrompt = args is Map ? args['prompt']?.toString() : null;
        return _Protected(
          allowedRoles: roleProtectedRouteMatrix[RouteConstants.chatbot],
          child: ChatbotScreen(
            moduleContext: moduleContext,
            initialPrompt: initialPrompt,
          ),
        );
      },
    ),
    GetPage(
      name: RouteConstants.changeEmail,
      binding: SettingsBinding(),
      page: () => const _Protected(child: ChangeEmailScreen()),
    ),
    GetPage(
      name: RouteConstants.changePassword,
      binding: SettingsBinding(),
      page: () => const _Protected(child: ChangePasswordScreen()),
    ),
    GetPage(
      name: RouteConstants.predictiveAnalytics,
      binding: PredictiveAnalyticsBinding(),
      page: () => _Protected(
        allowedRoles:
            roleProtectedRouteMatrix[RouteConstants.predictiveAnalytics],
        child: const PredictiveAnalyticsScreen(),
      ),
    ),
    GetPage(
      name: RouteConstants.adminAutomation,
      binding: AdminAutomationBinding(),
      page: () => _Protected(
        allowedRoles: roleProtectedRouteMatrix[RouteConstants.adminAutomation],
        child: const AdminAutomationScreen(),
      ),
    ),
  ];

  static final GetPage<dynamic> unknownRoute = GetPage<dynamic>(
    name: '/unknown',
    page: () => const _AuthGate(),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const SplashScreen();
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }
        if (auth.requiresEmailVerification) {
          return const VerifyEmailScreen();
        }
        return _roleHome(auth.role);
      },
    );
  }
}

class _Protected extends StatelessWidget {
  const _Protected({
    required this.child,
    this.allowUnverified = false,
    this.allowedRoles,
  });

  final Widget child;
  final bool allowUnverified;
  final Set<AppRole>? allowedRoles;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => RouteRoleGuard(
        isInitialized: auth.isInitialized,
        isAuthenticated: auth.isAuthenticated,
        requiresEmailVerification: auth.requiresEmailVerification,
        role: auth.role,
        allowUnverified: allowUnverified,
        allowedRoles: allowedRoles,
        child: child,
      ),
    );
  }
}

class _PublicOnly extends StatelessWidget {
  const _PublicOnly({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          return const SplashScreen();
        }
        if (!auth.isAuthenticated) {
          return child;
        }
        if (auth.requiresEmailVerification) {
          return const VerifyEmailScreen();
        }
        return _roleHome(auth.role);
      },
    );
  }
}

Widget _roleHome(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return const HomeScreen();
    case AppRole.teacher:
      return const AttendanceScreen();
    case AppRole.parent:
      return const ResultsScreen();
    case AppRole.student:
      return const TimetableScreen();
  }
}
