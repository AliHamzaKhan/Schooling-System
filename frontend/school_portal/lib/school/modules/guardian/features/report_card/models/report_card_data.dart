/// One subject line on the report card: a letter grade + percent, with an
/// optional course descriptor (e.g. "Advanced Algebra").
class ReportSubject {
  final String subject;
  final String? course;
  final String grade; // "A", "B+", "A-"
  final int percent; // 0..100
  const ReportSubject({
    required this.subject,
    this.course,
    required this.grade,
    required this.percent,
  });

  factory ReportSubject.fromJson(Map<String, dynamic> json) => ReportSubject(
        subject: json['subject'] as String? ?? '',
        course: json['course'] as String?,
        grade: json['grade'] as String? ?? '',
        percent: (json['percent'] as num?)?.toInt() ?? 0,
      );
}

/// One bar in the results trend: a published exam and its overall percentage.
class GpaTrendPoint {
  final String label; // exam name
  final double percent; // 0..100
  const GpaTrendPoint({required this.label, required this.percent});

  factory GpaTrendPoint.fromJson(Map<String, dynamic> json) => GpaTrendPoint(
        label: json['label'] as String? ?? '',
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
      );
}

/// Report-card view-model for the active child: the latest published exam's
/// subject results, its overall percentage and grade, and every published exam
/// as a trend (oldest first).
class ReportCardData {
  final String termLabel; // exam name
  final double averagePercent; // 0..100
  final String overallGrade;
  final List<ReportSubject> subjects;
  final List<GpaTrendPoint> gpaTrend;
  const ReportCardData({
    required this.termLabel,
    required this.averagePercent,
    this.overallGrade = '',
    required this.subjects,
    required this.gpaTrend,
  });

  factory ReportCardData.fromJson(Map<String, dynamic> json) => ReportCardData(
        termLabel: json['term_label'] as String? ?? '',
        averagePercent: (json['average_percent'] as num?)?.toDouble() ?? 0,
        overallGrade: json['grade'] as String? ?? '',
        subjects: ((json['subjects'] as List?) ?? [])
            .map((e) => ReportSubject.fromJson(e as Map<String, dynamic>))
            .toList(),
        gpaTrend: ((json['gpa_trend'] as List?) ?? [])
            .map((e) => GpaTrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
