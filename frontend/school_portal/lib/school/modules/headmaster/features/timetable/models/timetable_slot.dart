/// A minimal representation of a scheduled period, matching the backend
/// `TimetableSlotOut` schema.
class TimetableSlot {
  final String id;
  final String sectionId;
  final String subjectId;
  final String? teacherId;
  final int dayOfWeek; // 0 = Mon .. 6 = Sun
  final String startTime; // "HH:mm[:ss]"
  final String endTime;
  final String? room;

  const TimetableSlot({
    required this.id,
    required this.sectionId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.teacherId,
    this.room,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
        id: '${json['id']}',
        sectionId: '${json['section_id']}',
        subjectId: '${json['subject_id']}',
        teacherId: json['teacher_id']?.toString(),
        dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 0,
        startTime: json['start_time'] as String? ?? '00:00',
        endTime: json['end_time'] as String? ?? '00:00',
        room: json['room'] as String?,
      );

  String get startHm =>
      startTime.substring(0, startTime.length.clamp(0, 5));
  String get endHm => endTime.substring(0, endTime.length.clamp(0, 5));

  int _minutes(String hm) {
    final parts = hm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  int get startMinutes => _minutes(startTime);
  int get endMinutes => _minutes(endTime);
}

/// A subject stub used inside the timetable editor's subject dropdown.
class SubjectOption {
  final String id;
  final String code;
  final String name;
  const SubjectOption({
    required this.id,
    required this.code,
    required this.name,
  });

  factory SubjectOption.fromJson(Map<String, dynamic> json) => SubjectOption(
        id: '${json['id']}',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}
