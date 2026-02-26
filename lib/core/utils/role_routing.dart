import '../../features/auth/data/models/user_model.dart';
import '../../config/routes/route_constants.dart';

String landingRouteForRole(AppRole role) {
  switch (role) {
    case AppRole.admin:
      return RouteConstants.home;
    case AppRole.teacher:
      return RouteConstants.attendance;
    case AppRole.parent:
      return RouteConstants.results;
    case AppRole.student:
      return RouteConstants.timetable;
  }
}
