import 'package:flutter/foundation.dart';

import '../../config/routes/route_constants.dart';
import '../../features/auth/data/models/user_model.dart';

final Map<String, Set<AppRole>> roleProtectedRouteMatrix =
    Map<String, Set<AppRole>>.unmodifiable({
      RouteConstants.home: {AppRole.admin},
      RouteConstants.roleManagement: {AppRole.admin},
      RouteConstants.students: {AppRole.admin},
      RouteConstants.teachers: {AppRole.admin},
      RouteConstants.classes: {AppRole.admin},
      RouteConstants.subjects: {AppRole.admin},
      RouteConstants.attendance: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.parent,
        AppRole.student,
      },
      RouteConstants.exams: {AppRole.admin, AppRole.teacher},
      RouteConstants.results: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.parent,
        AppRole.student,
      },
      RouteConstants.fees: {AppRole.admin, AppRole.parent},
      RouteConstants.notifications: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.parent,
        AppRole.student,
      },
      RouteConstants.timetable: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.parent,
        AppRole.student,
      },
      RouteConstants.library: {AppRole.admin, AppRole.student},
      RouteConstants.transport: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.student,
      },
      RouteConstants.chatbot: {
        AppRole.admin,
        AppRole.teacher,
        AppRole.parent,
        AppRole.student,
      },
      RouteConstants.predictiveAnalytics: {AppRole.admin, AppRole.teacher},
      RouteConstants.adminAutomation: {AppRole.admin, AppRole.teacher},
    });

Set<AppRole>? allowedRolesForRoute(String route) {
  final allowed = roleProtectedRouteMatrix[route];
  if (allowed == null) return null;
  return Set<AppRole>.from(allowed);
}

bool canRoleAccessRoute({required AppRole role, required String route}) {
  final allowed = roleProtectedRouteMatrix[route];
  if (allowed == null) return false;
  return allowed.contains(role);
}

@visibleForTesting
Map<String, Set<AppRole>> copyRoleMatrix() {
  return {
    for (final entry in roleProtectedRouteMatrix.entries)
      entry.key: Set<AppRole>.from(entry.value),
  };
}
