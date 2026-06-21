import 'package:shared/shared.dart';

import 'attendance_data.dart';

class GuardianAttendanceRepository {
  Future<ApiResponse<GuardianAttendanceData>> load(String childId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return ApiResponse.ok(_byChild[childId] ?? _byChild['c1']!);
  }

  static const _byChild = <String, GuardianAttendanceData>{
    'c1': GuardianAttendanceData(
      monthlyPercent: 96,
      presentDays: 21,
      absentDays: 1,
      lateDays: 0,
      recent: [
        AttendanceRecord(date: 'Oct 14', status: AttendanceStatus.present),
        AttendanceRecord(date: 'Oct 13', status: AttendanceStatus.present),
        AttendanceRecord(
            date: 'Oct 12',
            status: AttendanceStatus.absent,
            note: 'Sick leave (approved)'),
        AttendanceRecord(date: 'Oct 11', status: AttendanceStatus.present),
        AttendanceRecord(date: 'Oct 10', status: AttendanceStatus.present),
      ],
    ),
    'c2': GuardianAttendanceData(
      monthlyPercent: 88,
      presentDays: 18,
      absentDays: 2,
      lateDays: 2,
      recent: [
        AttendanceRecord(
            date: 'Oct 14',
            status: AttendanceStatus.late,
            note: 'Arrived 12 mins late'),
        AttendanceRecord(date: 'Oct 13', status: AttendanceStatus.present),
        AttendanceRecord(date: 'Oct 12', status: AttendanceStatus.absent),
        AttendanceRecord(date: 'Oct 11', status: AttendanceStatus.present),
        AttendanceRecord(
            date: 'Oct 10',
            status: AttendanceStatus.late,
            note: 'Arrived 5 mins late'),
      ],
    ),
  };
}
