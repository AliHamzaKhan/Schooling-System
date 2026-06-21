import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/assignments/models/assignments_repository.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/exams/models/exam.dart';
import '../features/exams/models/exams_repository.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/notifications/models/notifications_repository.dart';
import 'student_api_service.dart';

/// Single data gateway for the Student module. Every Student controller depends
/// on this class (never on [StudentApiService] or [ApiService] directly).
///
/// Flip [_useMock] to `false` to route through the live [StudentApiService];
/// while `true` the methods return the bundled per-feature mock fixtures.
class StudentRepository {
  final StudentApiService _api;

  final _attendanceMock = AttendanceRepository();
  final _assignmentsMock = AssignmentsRepository();
  final _examsMock = ExamsRepository();
  final _notificationsMock = NotificationsRepository();

  StudentRepository({StudentApiService? api})
      : _api = api ?? StudentApiService();

  // Attendance, notifications, and single-assignment detail have no usable
  // backend mapping (attendance needs an academic student-record id with no
  // user link; there's no GET /assignments/{id}) → stay on mock.
  static const bool _useMock = true;

  // Per-feature live flags: real `/schools/{id}/...` calls (with documented
  // field losses — see StudentApiService). Flip to false to revert to mock.
  static const bool _liveAssignments = true;
  static const bool _liveExams = true;
  static const bool _liveSubmit = true;

  Future<ApiResponse<AttendanceData>> loadAttendance() =>
      _useMock ? _attendanceMock.load() : _api.fetchAttendance();

  Future<ApiResponse<AssignmentsData>> loadAssignments() =>
      _liveAssignments ? _api.fetchAssignments() : _assignmentsMock.load();

  Future<ApiResponse<StudentAssignment>> loadAssignment(String id) =>
      _useMock ? _assignmentsMock.fetchOne(id) : _api.fetchAssignment(id);

  Future<ApiResponse<ExamsData>> loadExams() =>
      _liveExams ? _api.fetchExams() : _examsMock.load();

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _useMock ? _notificationsMock.load() : _api.fetchNotifications();

  Future<ApiResponse<void>> submitAssignment(String id,
      {String? notes, String? filename}) async {
    if (_liveSubmit) {
      return _api.submitAssignment(id, notes: notes, filename: filename);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return ApiResponse.ok(null);
  }
}
