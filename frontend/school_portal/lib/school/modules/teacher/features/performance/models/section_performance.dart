/// One student's standing inside a section, as returned by
/// `GET /schools/{id}/academic/sections/{sectionId}/performance`.
class StudentStanding {
  final String studentId;
  final String fullName;
  final int presentDays;
  final int totalDays;

  /// 0..1 over the daily register.
  final double attendanceRate;

  /// 0..100 across every graded paper the student sat.
  final double averagePercentage;
  final int papersCounted;
  final String grade;

  /// 0..1 blend the backend ranks by.
  final double overallScore;

  const StudentStanding({
    required this.studentId,
    required this.fullName,
    required this.presentDays,
    required this.totalDays,
    required this.attendanceRate,
    required this.averagePercentage,
    required this.papersCounted,
    required this.grade,
    required this.overallScore,
  });

  /// True when the student has neither attendance nor marks recorded yet, so
  /// the UI can say "no data" instead of showing a misleading 0%.
  bool get hasNoData => totalDays == 0 && papersCounted == 0;

  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters().toUpperCase();
    return (parts.first.characters() + parts.last.characters()).toUpperCase();
  }

  factory StudentStanding.fromJson(Map<String, dynamic> json) => StudentStanding(
        studentId: '${json['student_id']}',
        fullName: json['full_name'] as String? ?? 'Student',
        presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
        totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
        attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0,
        averagePercentage:
            (json['average_percentage'] as num?)?.toDouble() ?? 0,
        papersCounted: (json['papers_counted'] as num?)?.toInt() ?? 0,
        grade: json['grade'] as String? ?? '—',
        overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      );
}

extension on String {
  String characters() => isEmpty ? '' : this[0];
}

class SectionPerformance {
  final String sectionId;
  final String sectionName;
  final String className;
  final List<StudentStanding> students;

  const SectionPerformance({
    required this.sectionId,
    required this.sectionName,
    required this.className,
    required this.students,
  });

  String get title => '$className $sectionName';

  factory SectionPerformance.fromJson(Map<String, dynamic> json) =>
      SectionPerformance(
        sectionId: '${json['section_id']}',
        sectionName: json['section_name'] as String? ?? '',
        className: json['class_name'] as String? ?? 'Class',
        students: ((json['students'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(StudentStanding.fromJson)
            .toList(),
      );
}
