import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/exams/models/exam.dart';
import '../features/notifications/models/notification_item.dart';
import 'student_endpoints.dart';

/// Network layer for the Student module. Owns every Student HTTP call, building
/// requests through the shared [ApiService] (auth headers, base URL, envelope
/// unwrapping, error handling) against [StudentEndpoints], and parsing payloads
/// into typed models. Controllers reach it only via `StudentRepository`.
class StudentApiService {
  final ApiService _api;
  StudentApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  Future<ApiResponse<AttendanceData>> fetchAttendance() {
    return _api.request<AttendanceData>(
      method: HttpMethod.get,
      path: StudentEndpoints.attendance,
      parser: (json) => AttendanceData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AssignmentsData>> fetchAssignments() {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: StudentEndpoints.assignments,
      parser: (json) => AssignmentsData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<StudentAssignment>> fetchAssignment(String id) {
    return _api.request<StudentAssignment>(
      method: HttpMethod.get,
      path: StudentEndpoints.assignment(id),
      parser: (json) =>
          StudentAssignment.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ExamsData>> fetchExams() {
    return _api.request<ExamsData>(
      method: HttpMethod.get,
      path: StudentEndpoints.exams,
      parser: (json) => ExamsData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<NotificationItem>>> fetchNotifications() {
    return _api.request<List<NotificationItem>>(
      method: HttpMethod.get,
      path: StudentEndpoints.notifications,
      parser: (json) => (json as List)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Submit an assignment (notes + optional attachment metadata).
  Future<ApiResponse<void>> submitAssignment(
    String id, {
    String? notes,
    String? filename,
  }) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: '${StudentEndpoints.assignment(id)}/submit',
      body: {
        'notes': ?notes,
        'filename': ?filename,
      },
    );
  }
}
