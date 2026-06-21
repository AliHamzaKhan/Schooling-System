import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/classes/models/classes_data.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/exams/models/exams_data.dart';
import '../features/fees/models/fees_data.dart';
import '../features/guardians/models/guardian.dart';
import '../features/overview/models/overview_data.dart';
import '../features/reports/models/reports_data.dart';
import '../features/students/models/student.dart';
import '../features/teachers/models/teacher.dart';
import '../features/timetable/models/timetable_data.dart';
import 'headmaster_endpoints.dart';

/// Network layer for the Headmaster module. Owns every Headmaster HTTP call,
/// building requests through the shared [ApiService] (auth headers, base URL,
/// envelope unwrapping, error handling) against [HeadmasterEndpoints], and
/// parsing payloads into typed models. Reached only via `HeadmasterRepository`.
class HeadmasterApiService {
  final ApiService _api;
  HeadmasterApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  Future<ApiResponse<DashboardData>> fetchDashboard() {
    return _api.request<DashboardData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.dashboard,
      parser: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<OverviewData>> fetchOverview() {
    return _api.request<OverviewData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.overview,
      parser: (json) => OverviewData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AttendanceData>> fetchAttendance(AttendanceRange range) {
    return _api.request<AttendanceData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.attendance,
      query: {'range': range.name},
      parser: (json) => AttendanceData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ExamsData>> fetchExams() {
    return _api.request<ExamsData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.exams,
      parser: (json) => ExamsData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<FeesData>> fetchFees() {
    return _api.request<FeesData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.fees,
      parser: (json) => FeesData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClassDirectoryData>> fetchClasses() {
    return _api.request<ClassDirectoryData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.classes,
      parser: (json) =>
          ClassDirectoryData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TimetableData>> fetchTimetable() {
    return _api.request<TimetableData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.timetable,
      parser: (json) => TimetableData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ReportsData>> fetchReports() {
    return _api.request<ReportsData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.reports,
      parser: (json) => ReportsData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Announcement>>> fetchAnnouncements({
    String filter = 'All Updates',
  }) {
    return _api.request<List<Announcement>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.announcements,
      query: {'filter': filter},
      parser: (json) => (json as List)
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<Teacher>>> fetchTeachers({String query = ''}) {
    return _api.request<List<Teacher>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.teachers,
      query: {'q': query},
      parser: (json) => (json as List)
          .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<Student>>> fetchStudents({
    String query = '',
    String? grade,
    String? section,
  }) {
    return _api.request<List<Student>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.students,
      query: {'q': query, 'grade': ?grade, 'section': ?section},
      parser: (json) => (json as List)
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<Guardian>>> fetchGuardians({String query = ''}) {
    return _api.request<List<Guardian>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.guardians,
      query: {'q': query},
      parser: (json) => (json as List)
          .map((e) => Guardian.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
