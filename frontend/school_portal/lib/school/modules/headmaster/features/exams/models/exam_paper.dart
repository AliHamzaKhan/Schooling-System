// One subject paper within an exam: the subject, its schedule (date + optional
// time), and its max / pass marks. Mirrors the backend `ExamSubjectOut`.
class ExamPaper {
  final String id;
  final String examId;
  final String subjectId;
  final double maxMarks;
  final double passMarks;
  final DateTime? examDate;
  final String? examTime;

  const ExamPaper({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.maxMarks,
    required this.passMarks,
    this.examDate,
    this.examTime,
  });

  factory ExamPaper.fromJson(Map<String, dynamic> j) => ExamPaper(
        id: '${j['id']}',
        examId: '${j['exam_id']}',
        subjectId: '${j['subject_id']}',
        maxMarks: (j['max_marks'] as num?)?.toDouble() ?? 0,
        passMarks: (j['pass_marks'] as num?)?.toDouble() ?? 0,
        examDate: j['exam_date'] is String && (j['exam_date'] as String).isNotEmpty
            ? DateTime.tryParse(j['exam_date'] as String)
            : null,
        examTime: j['exam_time'] as String?,
      );
}
