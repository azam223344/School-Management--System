import '../../../dashboard/data/services/school_management_service.dart';
import '../models/student_risk_prediction.dart';

class PredictiveAnalyticsService {
  List<StudentRiskPrediction> generatePredictions({
    required List<SchoolStudent> students,
    required List<SchoolClass> classes,
    required Map<String, dynamic> modules,
  }) {
    final scoresByStudent = _extractScoresByStudent(modules['results']);
    final classByStudent = _classByStudent(classes);

    final predictions = students.map((student) {
      final schoolClass = classByStudent[student.id];
      final attendanceRate = _attendanceRate(student.id, schoolClass);
      final averageScore = _average(scoresByStudent[student.id] ?? const []);
      final riskScore = _riskScore(
        attendanceRate: attendanceRate,
        averageScore: averageScore,
      );
      final riskBand = _riskBand(riskScore);
      return StudentRiskPrediction(
        studentId: student.id,
        studentName: student.name,
        className: schoolClass?.name ?? 'Unassigned',
        attendanceRate: attendanceRate,
        averageScore: averageScore,
        riskScore: riskScore,
        riskBand: riskBand,
        recommendedIntervention: _intervention(
          riskBand: riskBand,
          attendanceRate: attendanceRate,
          averageScore: averageScore,
        ),
      );
    }).toList();

    predictions.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return predictions;
  }

  Map<String, List<double>> _extractScoresByStudent(Object? rawResults) {
    final result = <String, List<double>>{};
    if (rawResults is! List) return result;

    for (final item in rawResults) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final studentId = (map['studentId'] ?? '').toString();
      final score = _toDouble(map['score']);
      if (studentId.isEmpty || score == null) continue;
      result.putIfAbsent(studentId, () => <double>[]).add(score);
    }
    return result;
  }

  Map<String, SchoolClass> _classByStudent(List<SchoolClass> classes) {
    final result = <String, SchoolClass>{};
    for (final schoolClass in classes) {
      for (final studentId in schoolClass.studentIds) {
        result[studentId] = schoolClass;
      }
    }
    return result;
  }

  double _attendanceRate(String studentId, SchoolClass? schoolClass) {
    if (schoolClass == null) return 0.5;
    final status = schoolClass.attendance[studentId];
    if (status == null) return 0.5;
    return status ? 1.0 : 0.0;
  }

  double _riskScore({
    required double attendanceRate,
    required double averageScore,
  }) {
    final attendanceRisk = 1.0 - attendanceRate.clamp(0.0, 1.0);
    final performanceRisk = 1.0 - (averageScore / 100).clamp(0.0, 1.0);
    final insufficientDataPenalty = averageScore == 0 ? 0.1 : 0.0;
    final score =
        (attendanceRisk * 0.55) +
        (performanceRisk * 0.35) +
        insufficientDataPenalty;
    return score.clamp(0.0, 1.0);
  }

  String _riskBand(double score) {
    if (score >= 0.7) return 'High';
    if (score >= 0.45) return 'Medium';
    return 'Low';
  }

  String _intervention({
    required String riskBand,
    required double attendanceRate,
    required double averageScore,
  }) {
    if (riskBand == 'High') {
      if (attendanceRate < 0.5) {
        return 'Start parent-teacher intervention and daily attendance follow-up.';
      }
      return 'Create a 2-week academic recovery plan with targeted remedial support.';
    }
    if (riskBand == 'Medium') {
      return 'Schedule weekly mentoring and monitor next two assessments closely.';
    }
    if (averageScore >= 85) {
      return 'Keep progress steady with enrichment tasks and positive reinforcement.';
    }
    return 'Continue routine monitoring and maintain consistent class engagement.';
  }

  double _average(List<double> scores) {
    if (scores.isEmpty) return 0;
    final sum = scores.reduce((a, b) => a + b);
    return sum / scores.length;
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
