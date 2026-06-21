import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/assignments/models/assignments_repository.dart';
import '../features/attendance/models/attendance_models.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/classes/models/classes_repository.dart';
import '../features/classes/models/teaching_class.dart';
import '../features/communication/models/communication_repository.dart';
import '../features/communication/models/message_thread.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/dashboard_repository.dart';
import '../features/gradebook/models/gradebook_data.dart';
import '../features/gradebook/models/gradebook_repository.dart';
import '../features/performance/models/performance_data.dart';
import '../features/performance/models/performance_repository.dart';
import 'teacher_api_service.dart';

/// Single data gateway for the Teacher module. Every Teacher controller depends
/// on this class (never on [TeacherApiService] or [ApiService] directly).
///
/// Flip [_useMock] to `false` to route through the live [TeacherApiService];
/// while `true` the methods return the bundled per-feature mock fixtures.
class TeacherRepository {
  final TeacherApiService _api;

  final _dashboardMock = DashboardRepository();
  final _classesMock = ClassesRepository();
  final _attendanceMock = AttendanceRepository();
  final _assignmentsMock = AssignmentsRepository();
  final _communicationMock = CommunicationRepository();
  final _gradebookMock = GradebookRepository();
  final _performanceMock = PerformanceRepository();

  TeacherRepository({TeacherApiService? api})
      : _api = api ?? TeacherApiService();

  static const bool _useMock = true;

  Future<ApiResponse<DashboardData>> loadDashboard() =>
      _useMock ? _dashboardMock.load() : _api.fetchDashboard();

  Future<ApiResponse<List<TeachingClass>>> loadClasses() =>
      _useMock ? _classesMock.fetch() : _api.fetchClasses();

  Future<ApiResponse<List<AttendanceClass>>> loadAttendanceClasses() =>
      _useMock ? _attendanceMock.fetchClasses() : _api.fetchAttendanceClasses();

  Future<ApiResponse<List<AttendanceStudent>>> loadAttendanceStudents(
          String classId) =>
      _useMock
          ? _attendanceMock.fetchStudents(classId)
          : _api.fetchAttendanceStudents(classId);

  Future<ApiResponse<void>> saveAttendanceMarks(
      String classId, Map<String, String> marks) async {
    if (!_useMock) return _api.saveAttendanceMarks(classId, marks);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiResponse.ok(null);
  }

  Future<ApiResponse<AssignmentsData>> loadAssignments({String? classFilter}) =>
      _useMock
          ? _assignmentsMock.load(classFilter: classFilter)
          : _api.fetchAssignments(classFilter: classFilter);

  Future<ApiResponse<List<MessageThread>>> loadMessages({
    String query = '',
    ThreadParty? party,
  }) =>
      _useMock
          ? _communicationMock.fetch(query: query, party: party)
          : _api.fetchMessages(query: query, party: party?.name);

  Future<ApiResponse<Gradebook>> loadGradebook(String? examId) =>
      _useMock
          ? _gradebookMock.load(examId)
          : _api.fetchGradebook(examId ?? '');

  Future<ApiResponse<StudentDetail>> loadStudentPerformance(
          String? studentId) =>
      _useMock
          ? _performanceMock.load(studentId)
          : _api.fetchStudentPerformance(studentId ?? '');

  Future<ApiResponse<void>> createHomework(Map<String, dynamic> payload) async {
    if (!_useMock) return _api.createHomework(payload);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return ApiResponse.ok(null);
  }

  Future<ApiResponse<void>> createExam(Map<String, dynamic> payload) async {
    if (!_useMock) return _api.createExam(payload);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return ApiResponse.ok(null);
  }
}
