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

/// A single bar in the GPA trend chart (e.g. "Q1" -> 3.4).
class GpaTrendPoint {
  final String label; // "Q1"
  final double gpa; // 0..4
  const GpaTrendPoint({required this.label, required this.gpa});

  factory GpaTrendPoint.fromJson(Map<String, dynamic> json) => GpaTrendPoint(
        label: json['label'] as String? ?? '',
        gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
      );
}

/// Report-card view-model for the active child: term results (subject grades),
/// the term GPA, and a GPA trend across recent terms.
class ReportCardData {
  final String termLabel; // "Term 1 Results"
  final double gpa; // 0..4
  final List<ReportSubject> subjects;
  final List<GpaTrendPoint> gpaTrend;
  const ReportCardData({
    required this.termLabel,
    required this.gpa,
    required this.subjects,
    required this.gpaTrend,
  });

  factory ReportCardData.fromJson(Map<String, dynamic> json) => ReportCardData(
        termLabel: json['term_label'] as String? ?? '',
        gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
        subjects: ((json['subjects'] as List?) ?? [])
            .map((e) => ReportSubject.fromJson(e as Map<String, dynamic>))
            .toList(),
        gpaTrend: ((json['gpa_trend'] as List?) ?? [])
            .map((e) => GpaTrendPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
