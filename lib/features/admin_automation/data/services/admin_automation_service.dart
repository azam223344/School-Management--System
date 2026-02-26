import '../../../../config/routes/route_constants.dart';
import '../../../dashboard/data/services/school_management_service.dart';
import '../models/admin_automation_recommendation.dart';

class AdminAutomationService {
  List<AdminAutomationRecommendation> buildRecommendations({
    required List<SchoolClass> classes,
    required Map<String, dynamic> modules,
  }) {
    final recommendations = <AdminAutomationRecommendation>[];
    final timetableCount = _safeListCount(modules['timetable']);
    final attendanceRecords = _safeMapList(modules['attendanceRecords']);
    final absentRate = _absentRate(attendanceRecords);

    final expectedTimetableSlots = classes.isEmpty ? 5 : classes.length * 5;
    if (timetableCount < expectedTimetableSlots) {
      recommendations.add(
        const AdminAutomationRecommendation(
          title: 'Smart Scheduling Assistant',
          description:
              'Detected timetable gaps. Use smart scheduling to auto-fill weekly slots and avoid class overlaps.',
          priority: 'High',
          impactScore: 0.9,
          route: RouteConstants.timetable,
        ),
      );
    }

    if (attendanceRecords.isEmpty || absentRate > 0.2) {
      recommendations.add(
        const AdminAutomationRecommendation(
          title: 'Automated Attendance Alerts',
          description:
              'Configure automatic absent-student alerts for teachers and parents to trigger early intervention.',
          priority: 'High',
          impactScore: 0.88,
          route: RouteConstants.attendance,
        ),
      );
    }

    recommendations.add(
      const AdminAutomationRecommendation(
        title: 'Administrative Chatbot Workflows',
        description:
            'Use chatbot quick actions for FAQs, policy lookup, and common admin requests to reduce manual support workload.',
        priority: 'Medium',
        impactScore: 0.72,
        route: RouteConstants.chatbot,
      ),
    );

    recommendations.add(
      const AdminAutomationRecommendation(
        title: 'Auto Weekly Operations Report',
        description:
            'Generate and share weekly summaries for attendance, assessments, and pending tasks automatically.',
        priority: 'Medium',
        impactScore: 0.68,
      ),
    );

    recommendations.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return recommendations;
  }

  double automationScore({
    required List<SchoolClass> classes,
    required Map<String, dynamic> modules,
  }) {
    final timetableCount = _safeListCount(modules['timetable']);
    final attendanceRecords = _safeMapList(modules['attendanceRecords']);
    final chatbotReady = 1.0;
    final timetableReadiness = classes.isEmpty
        ? 0.6
        : (timetableCount / (classes.length * 5)).clamp(0.0, 1.0);
    final attendanceAutomation = attendanceRecords.isEmpty
        ? 0.5
        : (1 - _absentRate(attendanceRecords)).clamp(0.0, 1.0);
    return ((timetableReadiness * 0.4) +
            (attendanceAutomation * 0.4) +
            (chatbotReady * 0.2))
        .clamp(0.0, 1.0);
  }

  int _safeListCount(Object? value) => value is List ? value.length : 0;

  List<Map<String, dynamic>> _safeMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double _absentRate(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final absentCount = records.where((r) => r['present'] != true).length;
    return absentCount / records.length;
  }
}
