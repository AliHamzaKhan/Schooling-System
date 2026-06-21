class ExamEntry {
  final String subject;
  final String date; // "Oct 24"
  final String time; // "09:00 AM"
  final String room; // "Hall A"
  final String? syllabus; // "Units 1–4"
  final String? result; // when published, e.g. "A — 91%"
  const ExamEntry({
    required this.subject,
    required this.date,
    required this.time,
    required this.room,
    this.syllabus,
    this.result,
  });

  bool get isPublished => result != null;

  factory ExamEntry.fromJson(Map<String, dynamic> json) => ExamEntry(
        subject: json['subject'] as String? ?? '',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        room: json['room'] as String? ?? '',
        syllabus: json['syllabus'] as String?,
        result: json['result'] as String?,
      );
}

class ExamData {
  final String termLabel;
  final List<ExamEntry> upcoming;
  final List<ExamEntry> results;
  const ExamData({
    required this.termLabel,
    required this.upcoming,
    required this.results,
  });

  factory ExamData.fromJson(Map<String, dynamic> json) => ExamData(
        termLabel: json['term_label'] as String? ?? '',
        upcoming: ((json['upcoming'] as List?) ?? [])
            .map((e) => ExamEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        results: ((json['results'] as List?) ?? [])
            .map((e) => ExamEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
