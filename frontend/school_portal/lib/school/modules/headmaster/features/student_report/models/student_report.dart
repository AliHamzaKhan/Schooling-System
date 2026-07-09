/// A guardian linked to the student (for messaging / meeting requests).
class ReportGuardian {
  final String id;
  final String name;
  const ReportGuardian({required this.id, required this.name});

  factory ReportGuardian.fromJson(Map<String, dynamic> j) =>
      ReportGuardian(id: '${j['id']}', name: j['name'] as String? ?? '');
}

class ReportAttendance {
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int total;
  final double percentage;

  const ReportAttendance({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.total,
    required this.percentage,
  });

  factory ReportAttendance.fromJson(Map<String, dynamic> j) => ReportAttendance(
        present: (j['present'] as num?)?.toInt() ?? 0,
        absent: (j['absent'] as num?)?.toInt() ?? 0,
        late: (j['late'] as num?)?.toInt() ?? 0,
        excused: (j['excused'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
      );
}

class ReportExam {
  final String examName;
  final double percentage;
  final String grade;
  final String status;
  const ReportExam({
    required this.examName,
    required this.percentage,
    required this.grade,
    required this.status,
  });

  factory ReportExam.fromJson(Map<String, dynamic> j) => ReportExam(
        examName: j['exam_name'] as String? ?? '',
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
        grade: j['grade'] as String? ?? '',
        status: j['status'] as String? ?? '',
      );
}

class ReportQuiz {
  final String title;
  final double? score;
  const ReportQuiz({required this.title, this.score});

  factory ReportQuiz.fromJson(Map<String, dynamic> j) => ReportQuiz(
        title: j['title'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble(),
      );
}

/// A 360-degree report for one student — attendance, exams, assignments,
/// quizzes, total points, and linked guardians.
class StudentReport {
  final String studentId;
  final String studentName;
  final List<ReportGuardian> guardians;
  final ReportAttendance attendance;
  final List<ReportExam> exams;
  final double examAverage;
  final int assignmentsTotal;
  final int assignmentsSubmitted;
  final List<ReportQuiz> quizzes;
  final double? quizAverage;
  final double totalPoints;

  const StudentReport({
    required this.studentId,
    required this.studentName,
    required this.guardians,
    required this.attendance,
    required this.exams,
    required this.examAverage,
    required this.assignmentsTotal,
    required this.assignmentsSubmitted,
    required this.quizzes,
    required this.quizAverage,
    required this.totalPoints,
  });

  factory StudentReport.fromJson(Map<String, dynamic> j) => StudentReport(
        studentId: '${j['student_id']}',
        studentName: j['student_name'] as String? ?? '',
        guardians: ((j['guardians'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ReportGuardian.fromJson)
            .toList(),
        attendance: ReportAttendance.fromJson(
            (j['attendance'] as Map<String, dynamic>?) ?? const {}),
        exams: ((j['exams'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ReportExam.fromJson)
            .toList(),
        examAverage: (j['exam_average'] as num?)?.toDouble() ?? 0,
        assignmentsTotal: (j['assignments_total'] as num?)?.toInt() ?? 0,
        assignmentsSubmitted:
            (j['assignments_submitted'] as num?)?.toInt() ?? 0,
        quizzes: ((j['quizzes'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ReportQuiz.fromJson)
            .toList(),
        quizAverage: (j['quiz_average'] as num?)?.toDouble(),
        totalPoints: (j['total_points'] as num?)?.toDouble() ?? 0,
      );
}
