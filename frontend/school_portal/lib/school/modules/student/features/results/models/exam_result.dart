/// One published exam result on the student's academic results screen.
class ExamResultItem {
  final String examId;
  final String examName;
  final double totalMarks;
  final double maxTotal;
  final double percentage;
  final String grade;
  final String status; // pass / fail

  const ExamResultItem({
    required this.examId,
    required this.examName,
    required this.totalMarks,
    required this.maxTotal,
    required this.percentage,
    required this.grade,
    required this.status,
  });

  bool get passed => status.toLowerCase() == 'pass';

  factory ExamResultItem.fromJson(Map<String, dynamic> j) => ExamResultItem(
        examId: '${j['exam_id']}',
        examName: j['exam_name'] as String? ?? '',
        totalMarks: (j['total_marks'] as num?)?.toDouble() ?? 0,
        maxTotal: (j['max_total'] as num?)?.toDouble() ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
        grade: j['grade'] as String? ?? '',
        status: j['status'] as String? ?? '',
      );
}
