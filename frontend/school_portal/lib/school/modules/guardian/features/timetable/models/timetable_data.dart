/// A single period on a day's timetable: a class (subject/teacher/room) or a
/// break (set [isBreak] true, e.g. "Lunch Break").
class TimetableEntry {
  final String subject;
  final String? note; // e.g. "Focus on Binary Trees"
  final String startTime; // "10:00"
  final String endTime; // "11:30"
  final String? teacher;
  final String? room;
  final bool isNow; // currently in session
  final bool isBreak;
  const TimetableEntry({
    required this.subject,
    this.note,
    required this.startTime,
    required this.endTime,
    this.teacher,
    this.room,
    this.isNow = false,
    this.isBreak = false,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        subject: json['subject'] as String? ?? '',
        note: json['note'] as String?,
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        teacher: json['teacher'] as String?,
        room: json['room'] as String?,
        isNow: json['is_now'] as bool? ?? false,
        isBreak: json['is_break'] as bool? ?? false,
      );
}

/// One day column in the week selector, holding that day's periods.
class TimetableDay {
  final String weekday; // "Tue"
  final String dayNum; // "13"
  final bool isToday;
  final List<TimetableEntry> entries;
  const TimetableDay({
    required this.weekday,
    required this.dayNum,
    this.isToday = false,
    required this.entries,
  });

  factory TimetableDay.fromJson(Map<String, dynamic> json) => TimetableDay(
        weekday: json['weekday'] as String? ?? '',
        dayNum: json['day_num'] as String? ?? '',
        isToday: json['is_today'] as bool? ?? false,
        entries: ((json['entries'] as List?) ?? [])
            .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Weekly timetable view-model for the active child.
class TimetableData {
  final String weekLabel; // "Week of October 12th"
  final List<TimetableDay> days;
  const TimetableData({required this.weekLabel, required this.days});

  factory TimetableData.fromJson(Map<String, dynamic> json) => TimetableData(
        weekLabel: json['week_label'] as String? ?? '',
        days: ((json['days'] as List?) ?? [])
            .map((e) => TimetableDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
