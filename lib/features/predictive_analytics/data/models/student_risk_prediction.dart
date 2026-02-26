class StudentRiskPrediction {
  const StudentRiskPrediction({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.attendanceRate,
    required this.averageScore,
    required this.riskScore,
    required this.riskBand,
    required this.recommendedIntervention,
  });

  final String studentId;
  final String studentName;
  final String className;
  final double attendanceRate;
  final double averageScore;
  final double riskScore;
  final String riskBand;
  final String recommendedIntervention;
}
