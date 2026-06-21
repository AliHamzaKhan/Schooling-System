class SubjectGrade {
  final String subject;
  final String grade; // "A", "B+"
  final int percent; // 0..100
  final double deltaPercent; // change vs last term
  const SubjectGrade({
    required this.subject,
    required this.grade,
    required this.percent,
    required this.deltaPercent,
  });

  factory SubjectGrade.fromJson(Map<String, dynamic> json) => SubjectGrade(
        subject: json['subject'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        percent: (json['percent'] as num?)?.toInt() ?? 0,
        deltaPercent: (json['delta_percent'] as num?)?.toDouble() ?? 0,
      );
}

class PerformanceData {
  final double gpa; // 0..4
  final int classRank;
  final int classSize;
  final String termLabel; // "Term 2 — 2025/26"
  final List<SubjectGrade> subjects;
  final List<double> gpaTrend; // recent terms, for the trend line

  const PerformanceData({
    required this.gpa,
    required this.classRank,
    required this.classSize,
    required this.termLabel,
    required this.subjects,
    required this.gpaTrend,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) => PerformanceData(
        gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
        classRank: (json['class_rank'] as num?)?.toInt() ?? 0,
        classSize: (json['class_size'] as num?)?.toInt() ?? 0,
        termLabel: json['term_label'] as String? ?? '',
        subjects: ((json['subjects'] as List?) ?? [])
            .map((e) => SubjectGrade.fromJson(e as Map<String, dynamic>))
            .toList(),
        gpaTrend: ((json['gpa_trend'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}
