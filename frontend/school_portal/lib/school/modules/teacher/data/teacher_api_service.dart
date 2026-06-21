import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/attendance/models/attendance_models.dart';
import '../features/classes/models/teaching_class.dart';
import '../features/communication/models/message_thread.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/gradebook/models/gradebook_data.dart';
import '../features/performance/models/performance_data.dart';
import 'teacher_endpoints.dart';

/// Network layer for the Teacher module. Owns every Teacher HTTP call, building
/// requests through the shared [ApiService] (auth headers, base URL, envelope
/// unwrapping, error handling) against [TeacherEndpoints], and parsing payloads
/// into typed models. Reached only via `TeacherRepository`.
class TeacherApiService {
  final ApiService _api;
  TeacherApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  Future<ApiResponse<DashboardData>> fetchDashboard() {
    return _api.request<DashboardData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.dashboard,
      parser: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<TeachingClass>>> fetchClasses() {
    return _api.request<List<TeachingClass>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.classes,
      parser: (json) => (json as List)
          .map((e) => TeachingClass.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<AttendanceClass>>> fetchAttendanceClasses() {
    return _api.request<List<AttendanceClass>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.attendanceClasses,
      parser: (json) => (json as List)
          .map((e) => AttendanceClass.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<AttendanceStudent>>> fetchAttendanceStudents(
      String classId) {
    return _api.request<List<AttendanceStudent>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.attendanceStudents(classId),
      parser: (json) => (json as List)
          .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<void>> saveAttendanceMarks(
      String classId, Map<String, String> marks) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.attendanceMarks(classId),
      body: {'marks': marks},
    );
  }

  Future<ApiResponse<AssignmentsData>> fetchAssignments({String? classFilter}) {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.assignments,
      query: {'class': ?classFilter},
      parser: (json) => AssignmentsData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<MessageThread>>> fetchMessages({
    String query = '',
    String? party,
  }) {
    return _api.request<List<MessageThread>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.messages,
      query: {'q': query, 'party': ?party},
      parser: (json) => (json as List)
          .map((e) => MessageThread.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<Gradebook>> fetchGradebook(String examId) {
    return _api.request<Gradebook>(
      method: HttpMethod.get,
      path: TeacherEndpoints.gradebook(examId),
      parser: (json) => Gradebook.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<StudentDetail>> fetchStudentPerformance(String studentId) {
    return _api.request<StudentDetail>(
      method: HttpMethod.get,
      path: TeacherEndpoints.studentPerformance(studentId),
      parser: (json) => StudentDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> createHomework(Map<String, dynamic> payload) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.homework,
      body: payload,
    );
  }

  Future<ApiResponse<void>> createExam(Map<String, dynamic> payload) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.exams,
      body: payload,
    );
  }
}
