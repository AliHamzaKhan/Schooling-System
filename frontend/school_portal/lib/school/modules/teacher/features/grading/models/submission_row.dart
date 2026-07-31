// One student's submission in the teacher's grading view. Mirrors the backend
// `SubmissionOut` (with composed student_name and the read-receipt seen_at).

class SubmissionRow {
  final String id;
  final String studentId;
  final String? studentName;
  final String submittedOn;
  final String? content;
  final String? attachmentUrl;
  final String status; // submitted | late | graded | approved | rejected
  final double? marksObtained;
  final String? feedback;
  final bool seen;

  const SubmissionRow({
    required this.id,
    required this.studentId,
    required this.status,
    required this.submittedOn,
    this.studentName,
    this.content,
    this.attachmentUrl,
    this.marksObtained,
    this.feedback,
    this.seen = false,
  });

  bool get isGraded => status == 'graded';
  bool get isLate => status == 'late';

  factory SubmissionRow.fromJson(Map<String, dynamic> j) => SubmissionRow(
        id: '${j['id']}',
        studentId: '${j['student_id']}',
        studentName: j['student_name'] as String?,
        submittedOn: j['submitted_on'] as String? ?? '',
        content: j['content'] as String?,
        attachmentUrl: j['attachment_url'] as String?,
        status: (j['status'] as String? ?? '').toLowerCase(),
        marksObtained: (j['marks_obtained'] as num?)?.toDouble(),
        feedback: j['feedback'] as String?,
        seen: j['seen_at'] != null,
      );
}
