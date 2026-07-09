/// One period on the student's timetable.
class TimetablePeriod {
  final String subject;
  final String? teacher;
  final String? room;
  final String start; // "08:30"
  final String end; // "09:30"

  const TimetablePeriod({
    required this.subject,
    required this.start,
    required this.end,
    this.teacher,
    this.room,
  });
}

/// A weekday column with its periods.
class TimetableDay {
  final int weekday; // 0=Mon .. 6=Sun
  final String label; // "Mon"
  final bool isToday;
  final List<TimetablePeriod> periods;

  const TimetableDay({
    required this.weekday,
    required this.label,
    required this.isToday,
    required this.periods,
  });
}
