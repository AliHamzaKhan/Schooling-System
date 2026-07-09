/// One subject row on an exam report card.
class ReportCardLine {
  final String subject;
  final double maxMarks;
  final double? marksObtained;
  final bool isAbsent;
  final bool passed;

  const ReportCardLine({
    required this.subject,
    required this.maxMarks,
    required this.marksObtained,
    required this.isAbsent,
    required this.passed,
  });
}

/// A student's per-subject report card for one exam.
class ReportCard {
  final double totalMarks;
  final double maxTotal;
  final double percentage;
  final String grade;
  final String status; // pass / fail
  final bool published;
  final List<ReportCardLine> lines;

  const ReportCard({
    required this.totalMarks,
    required this.maxTotal,
    required this.percentage,
    required this.grade,
    required this.status,
    required this.published,
    required this.lines,
  });

  bool get passed => status.toLowerCase() == 'pass';
}
