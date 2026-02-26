import 'package:flutter_test/flutter_test.dart';

import 'package:auth_app/config/routes/route_constants.dart';
import 'package:auth_app/core/utils/role_permissions.dart';
import 'package:auth_app/core/utils/role_routing.dart';
import 'package:auth_app/features/auth/data/models/user_model.dart';

void main() {
  group('Role landing routes', () {
    test('maps every role to correct landing screen', () {
      expect(landingRouteForRole(AppRole.admin), RouteConstants.home);
      expect(landingRouteForRole(AppRole.teacher), RouteConstants.attendance);
      expect(landingRouteForRole(AppRole.parent), RouteConstants.results);
      expect(landingRouteForRole(AppRole.student), RouteConstants.timetable);
    });
  });

  group('Role access matrix', () {
    test('includes all key protected module routes', () {
      final matrix = copyRoleMatrix();
      const expectedRoutes = <String>{
        RouteConstants.home,
        RouteConstants.roleManagement,
        RouteConstants.students,
        RouteConstants.teachers,
        RouteConstants.classes,
        RouteConstants.subjects,
        RouteConstants.attendance,
        RouteConstants.exams,
        RouteConstants.results,
        RouteConstants.fees,
        RouteConstants.notifications,
        RouteConstants.timetable,
        RouteConstants.library,
        RouteConstants.transport,
        RouteConstants.chatbot,
        RouteConstants.predictiveAnalytics,
        RouteConstants.adminAutomation,
      };
      expect(matrix.keys.toSet(), expectedRoutes);
    });

    test('enforces expected access for each role', () {
      const expected = <AppRole, Set<String>>{
        AppRole.admin: {
          RouteConstants.home,
          RouteConstants.roleManagement,
          RouteConstants.students,
          RouteConstants.teachers,
          RouteConstants.classes,
          RouteConstants.subjects,
          RouteConstants.attendance,
          RouteConstants.exams,
          RouteConstants.results,
          RouteConstants.fees,
          RouteConstants.notifications,
          RouteConstants.timetable,
          RouteConstants.library,
          RouteConstants.transport,
          RouteConstants.chatbot,
          RouteConstants.predictiveAnalytics,
          RouteConstants.adminAutomation,
        },
        AppRole.teacher: {
          RouteConstants.attendance,
          RouteConstants.exams,
          RouteConstants.results,
          RouteConstants.notifications,
          RouteConstants.timetable,
          RouteConstants.transport,
          RouteConstants.chatbot,
          RouteConstants.predictiveAnalytics,
          RouteConstants.adminAutomation,
        },
        AppRole.parent: {
          RouteConstants.attendance,
          RouteConstants.results,
          RouteConstants.fees,
          RouteConstants.notifications,
          RouteConstants.timetable,
          RouteConstants.chatbot,
        },
        AppRole.student: {
          RouteConstants.attendance,
          RouteConstants.results,
          RouteConstants.notifications,
          RouteConstants.timetable,
          RouteConstants.library,
          RouteConstants.transport,
          RouteConstants.chatbot,
        },
      };

      final allRoutes = roleProtectedRouteMatrix.keys.toSet();
      for (final role in AppRole.values) {
        final allowedForRole = expected[role]!;
        for (final route in allRoutes) {
          expect(
            canRoleAccessRoute(role: role, route: route),
            allowedForRole.contains(route),
            reason: 'role=${role.name} route=$route',
          );
        }
      }
    });

    test('returns null/false for unknown route', () {
      expect(allowedRolesForRoute('/unknown-route'), isNull);
      expect(
        canRoleAccessRoute(role: AppRole.admin, route: '/unknown-route'),
        isFalse,
      );
    });
  });
}
