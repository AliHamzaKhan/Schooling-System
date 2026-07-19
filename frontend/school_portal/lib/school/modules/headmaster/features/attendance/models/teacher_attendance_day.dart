/// Attendance status for a teacher on a given day.
enum TeacherAttendanceStatus { present, absent, late, onLeave, unmarked }

extension TeacherAttendanceStatusX on TeacherAttendanceStatus {
  String get wire => switch (this) {
        TeacherAttendanceStatus.present => 'present',
        TeacherAttendanceStatus.absent => 'absent',
        TeacherAttendanceStatus.late => 'late',
        TeacherAttendanceStatus.onLeave => 'on_leave',
        TeacherAttendanceStatus.unmarked => 'unmarked',
      };

  String get label => switch (this) {
        TeacherAttendanceStatus.present => 'Present',
        TeacherAttendanceStatus.absent => 'Absent',
        TeacherAttendanceStatus.late => 'Late',
        TeacherAttendanceStatus.onLeave => 'On leave',
        TeacherAttendanceStatus.unmarked => 'Not marked',
      };

  static TeacherAttendanceStatus fromWire(String? raw) => switch (raw) {
        'present' => TeacherAttendanceStatus.present,
        'absent' => TeacherAttendanceStatus.absent,
        'late' => TeacherAttendanceStatus.late,
        'on_leave' => TeacherAttendanceStatus.onLeave,
        _ => TeacherAttendanceStatus.unmarked,
      };
}

/// One teacher row in the day's attendance roster.
class TeacherAttendanceRow {
  final String teacherId;
  final String teacherName;
  final TeacherAttendanceStatus status;
  final String? arrivalTime; // "HH:mm[:ss]"
  final String? remarks;

  const TeacherAttendanceRow({
    required this.teacherId,
    required this.teacherName,
    required this.status,
    this.arrivalTime,
    this.remarks,
  });

  factory TeacherAttendanceRow.fromJson(Map<String, dynamic> json) =>
      TeacherAttendanceRow(
        teacherId: '${json['teacher_id']}',
        teacherName: json['teacher_name'] as String? ?? '',
        status: TeacherAttendanceStatusX.fromWire(json['status'] as String?),
        arrivalTime: json['arrival_time'] as String?,
        remarks: json['remarks'] as String?,
      );

  TeacherAttendanceRow copyWith({
    TeacherAttendanceStatus? status,
    String? arrivalTime,
  }) =>
      TeacherAttendanceRow(
        teacherId: teacherId,
        teacherName: teacherName,
        status: status ?? this.status,
        arrivalTime: arrivalTime ?? this.arrivalTime,
        remarks: remarks,
      );
}

/// Aggregate view of one day's teacher attendance.
class TeacherAttendanceDay {
  final DateTime date;
  final int totalTeachers;
  final int present;
  final int absent;
  final int late;
  final int onLeave;
  final int unmarked;
  final List<TeacherAttendanceRow> entries;

  const TeacherAttendanceDay({
    required this.date,
    required this.totalTeachers,
    required this.present,
    required this.absent,
    required this.late,
    required this.onLeave,
    required this.unmarked,
    required this.entries,
  });

  factory TeacherAttendanceDay.fromJson(Map<String, dynamic> json) =>
      TeacherAttendanceDay(
        date: DateTime.tryParse(json['attendance_date'] as String? ?? '') ??
            DateTime.now(),
        totalTeachers: (json['total_teachers'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        late: (json['late'] as num?)?.toInt() ?? 0,
        onLeave: (json['on_leave'] as num?)?.toInt() ?? 0,
        unmarked: (json['unmarked'] as num?)?.toInt() ?? 0,
        entries: ((json['entries'] as List?) ?? [])
            .map((e) =>
                TeacherAttendanceRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  double get presentRate =>
      totalTeachers == 0 ? 0 : present / totalTeachers;
}
