/// One day's attendance record in the guardian view.
enum AttendanceStatus { present, absent, late, holiday }

class AttendanceRecord {
  final String date; // "Oct 14"
  final AttendanceStatus status;
  final String? note; // e.g. "Arrived 10 mins late"
  const AttendanceRecord({required this.date, required this.status, this.note});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: json['date'] as String? ?? '',
        status: AttendanceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AttendanceStatus.present,
        ),
        note: json['note'] as String?,
      );
}

class GuardianAttendanceData {
  final int monthlyPercent;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final List<AttendanceRecord> recent;

  const GuardianAttendanceData({
    required this.monthlyPercent,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.recent,
  });

  factory GuardianAttendanceData.fromJson(Map<String, dynamic> json) =>
      GuardianAttendanceData(
        monthlyPercent: (json['monthly_percent'] as num?)?.toInt() ?? 0,
        presentDays: (json['present_days'] as num?)?.toInt() ?? 0,
        absentDays: (json['absent_days'] as num?)?.toInt() ?? 0,
        lateDays: (json['late_days'] as num?)?.toInt() ?? 0,
        recent: ((json['recent'] as List?) ?? [])
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
