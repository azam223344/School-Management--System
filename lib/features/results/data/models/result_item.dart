class ResultItem {
  const ResultItem({
    required this.id,
    required this.examTitle,
    required this.subject,
    required this.score,
    required this.grade,
    required this.classId,
    required this.studentId,
  });

  final String id;
  final String examTitle;
  final String subject;
  final double score;
  final String grade;
  final String classId;
  final String studentId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examTitle': examTitle,
      'subject': subject,
      'score': score,
      'grade': grade,
      'classId': classId,
      'studentId': studentId,
    };
  }

  factory ResultItem.fromMap(Map<String, dynamic> map) {
    return ResultItem(
      id: (map['id'] ?? '').toString(),
      examTitle: (map['examTitle'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      score: ((map['score'] ?? 0) as num).toDouble(),
      grade: (map['grade'] ?? '').toString(),
      classId: (map['classId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
    );
  }
}
