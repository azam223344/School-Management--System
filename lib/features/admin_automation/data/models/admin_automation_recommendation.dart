class AdminAutomationRecommendation {
  const AdminAutomationRecommendation({
    required this.title,
    required this.description,
    required this.priority,
    required this.impactScore,
    this.route,
  });

  final String title;
  final String description;
  final String priority;
  final double impactScore;
  final String? route;
}
