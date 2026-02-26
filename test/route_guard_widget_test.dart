import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auth_app/features/auth/data/models/user_model.dart';
import 'package:auth_app/core/widgets/route_role_guard.dart';

void main() {
  Widget hostWidget(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('shows Access Restricted for unauthorized role', (tester) async {
    await tester.pumpWidget(
      hostWidget(
        const RouteRoleGuard(
          isInitialized: true,
          isAuthenticated: true,
          requiresEmailVerification: false,
          role: AppRole.teacher,
          allowedRoles: {AppRole.admin},
          child: Scaffold(body: Text('Secret Content')),
        ),
      ),
    );

    expect(find.text('Access Restricted'), findsOneWidget);
    expect(
      find.text('This section is not available for your role.'),
      findsOneWidget,
    );
    expect(find.text('Secret Content'), findsNothing);
  });

  testWidgets('shows protected child for authorized role', (tester) async {
    await tester.pumpWidget(
      hostWidget(
        const RouteRoleGuard(
          isInitialized: true,
          isAuthenticated: true,
          requiresEmailVerification: false,
          role: AppRole.admin,
          allowedRoles: {AppRole.admin},
          child: Scaffold(body: Text('Secret Content')),
        ),
      ),
    );

    expect(find.text('Secret Content'), findsOneWidget);
    expect(find.text('Access Restricted'), findsNothing);
  });

  testWidgets('shows Login screen when user is unauthenticated', (tester) async {
    await tester.pumpWidget(
      hostWidget(
        const RouteRoleGuard(
          isInitialized: true,
          isAuthenticated: false,
          requiresEmailVerification: false,
          role: AppRole.student,
          allowedRoles: {AppRole.admin},
          loginFallback: Scaffold(body: Text('Login Fallback')),
          child: Scaffold(body: Text('Secret Content')),
        ),
      ),
    );

    expect(find.text('Login Fallback'), findsOneWidget);
    expect(find.text('Secret Content'), findsNothing);
    expect(find.text('Access Restricted'), findsNothing);
  });
}
