import 'package:shared/shared.dart';

import 'attendance_data.dart';

class AttendanceRepository {
  Future<ApiResponse<AttendanceData>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  static const _mock = AttendanceData(
    monthlyAverage: 96,
    deltaPercent: 2,
    week: [
      DayBar('Mon', 1.0),
      DayBar('Tue', 1.0),
      DayBar('Wed', 0.45), // late
      DayBar('Thu', 1.0),
      DayBar('Fri', 1.0),
    ],
    recentAbsences: [],
    lateMarks: [
      LateMark(date: 'Oct 12', period: 'Morning Homeroom', minutes: 5),
    ],
  );
}
