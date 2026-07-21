/// One period on the signed-in teacher's weekly timetable, as returned by
/// `GET /schools/{id}/academic/me/timetable`.
class TeacherSlot {
  final String id;

  /// 0 = Monday .. 6 = Sunday, matching the backend's `day_of_week`.
  final int dayOfWeek;
  final Duration start;
  final Duration end;
  final String sectionId;
  final String sectionName;
  final String className;
  final String subjectId;
  final String subject;
  final String? room;
  final int studentCount;
  final bool isClassTeacher;

  /// Whether this period's attendance is already saved for the requested date.
  final bool attendanceMarked;

  const TeacherSlot({
    required this.id,
    required this.dayOfWeek,
    required this.start,
    required this.end,
    required this.sectionId,
    required this.sectionName,
    required this.className,
    required this.subjectId,
    required this.subject,
    required this.studentCount,
    this.room,
    this.isClassTeacher = false,
    this.attendanceMarked = false,
  });

  String get title => '$subject · $className $sectionName';

  /// The period's start as a concrete moment on [day], so callers can compare
  /// it against `DateTime.now()` for countdowns.
  DateTime startsOn(DateTime day) =>
      DateTime(day.year, day.month, day.day).add(start);

  DateTime endsOn(DateTime day) =>
      DateTime(day.year, day.month, day.day).add(end);

  /// "09:00 – 10:00" for the card header.
  String get timeRange => '${_hhmm(start)} – ${_hhmm(end)}';

  static String _hhmm(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Parses the backend's "HH:MM:SS" time-of-day into a [Duration] offset.
  static Duration _parseTime(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length < 2) return Duration.zero;
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
    );
  }

  factory TeacherSlot.fromJson(Map<String, dynamic> json) => TeacherSlot(
        id: '${json['id']}',
        dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
        start: _parseTime(json['start_time'] as String?),
        end: _parseTime(json['end_time'] as String?),
        sectionId: '${json['section_id']}',
        sectionName: json['section_name'] as String? ?? '',
        className: json['class_name'] as String? ?? '',
        subjectId: '${json['subject_id']}',
        subject: json['subject'] as String? ?? '',
        room: json['room'] as String?,
        studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
        isClassTeacher: json['is_class_teacher'] as bool? ?? false,
        attendanceMarked: json['attendance_marked'] as bool? ?? false,
      );
}
