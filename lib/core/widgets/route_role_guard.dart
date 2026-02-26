import 'package:flutter/material.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import 'role_denied_screen.dart';

class RouteRoleGuard extends StatelessWidget {
  const RouteRoleGuard({
    super.key,
    required this.child,
    required this.isInitialized,
    required this.isAuthenticated,
    required this.requiresEmailVerification,
    required this.role,
    this.allowUnverified = false,
    this.allowedRoles,
    this.splashFallback,
    this.loginFallback,
    this.verifyEmailFallback,
    this.deniedFallback,
  });

  final Widget child;
  final bool isInitialized;
  final bool isAuthenticated;
  final bool requiresEmailVerification;
  final AppRole role;
  final bool allowUnverified;
  final Set<AppRole>? allowedRoles;
  final Widget? splashFallback;
  final Widget? loginFallback;
  final Widget? verifyEmailFallback;
  final Widget? deniedFallback;

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return splashFallback ?? const SplashScreen();
    }
    if (!isAuthenticated) {
      return loginFallback ?? const LoginScreen();
    }
    if (!allowUnverified && requiresEmailVerification) {
      return verifyEmailFallback ?? const VerifyEmailScreen();
    }
    if (allowedRoles != null && !allowedRoles!.contains(role)) {
      return deniedFallback ?? const RoleDeniedScreen();
    }
    return child;
  }
}
