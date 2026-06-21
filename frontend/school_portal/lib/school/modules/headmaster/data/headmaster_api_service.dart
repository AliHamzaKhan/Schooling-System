import 'package:flutter/material.dart';
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

  /// The signed-in headmaster's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

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

  /// Live exams from `/schools/{id}/exams` (list of `ExamOut`: name, status,
  /// dates). Builds the schedule + active/upcoming counts; the backend has no
  /// grade distribution or recent-results feed, so those stay empty.
  Future<ApiResponse<ExamsData>> fetchExams() {
    return _api.request<ExamsData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.examsList(_sid),
      parser: (json) {
        final list = (json as List).cast<Map<String, dynamic>>();
        final schedule = list.map((e) {
          final status = _examStatus(e['status'] as String?);
          final start = e['start_date'] as String?;
          final end = e['end_date'] as String?;
          final when = [start, end].where((d) => d != null).join(' – ');
          return ExamScheduleItem(
            id: '${e['id']}',
            subject: e['name'] as String? ?? '',
            grade: '',
            schedule: when,
            location: '',
            icon: Icons.school_outlined,
            iconColor: AppColors.primary,
            status: status,
          );
        }).toList();
        return ExamsData(
          activeExams: schedule.where((s) => s.status == ExamStatus.live).length,
          upcomingExams:
              schedule.where((s) => s.status == ExamStatus.upcoming).length,
          pendingResults: 0,
          schedule: schedule,
          recent: const [],
          gradeDistribution: const {},
        );
      },
    );
  }

  ExamStatus _examStatus(String? s) => switch (s) {
        'active' || 'ongoing' || 'live' => ExamStatus.live,
        'completed' || 'published' || 'finished' => ExamStatus.completed,
        _ => ExamStatus.upcoming,
      };

  Future<ApiResponse<FeesData>> fetchFees() {
    return _api.request<FeesData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.fees,
      parser: (json) => FeesData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Live classes from `/schools/{id}/academic/classes` (list of `ClassOut`:
  /// id, name, level). The backend exposes no per-section student counts or
  /// KPIs, so sections carry 0 students and only a "Total Classes" stat shows.
  Future<ApiResponse<ClassDirectoryData>> fetchClasses() {
    return _api.request<ClassDirectoryData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicClasses(_sid),
      parser: (json) {
        final list = (json as List).cast<Map<String, dynamic>>();
        final grades = list.map((c) {
          final level = (c['level'] as num?)?.toInt() ?? 0;
          return GradeGroup(
            grade: level,
            level: _gradeLevel(level),
            sections: [
              ClassSection(
                id: '${c['id']}',
                name: c['name'] as String? ?? '',
                students: 0,
                accent: AppColors.primary,
              ),
            ],
          );
        }).toList();
        return ClassDirectoryData(
          stats: [
            ClassStat(
              label: 'Total Classes',
              value: '${list.length}',
              icon: Icons.class_outlined,
              color: AppColors.primary,
            ),
          ],
          grades: grades,
        );
      },
    );
  }

  GradeLevel _gradeLevel(int level) {
    if (level >= 9) return GradeLevel.high;
    if (level >= 6) return GradeLevel.middle;
    return GradeLevel.primary;
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

  /// Live teachers from `/schools/{id}/users?role_code=teacher`. The backend
  /// user payload has no department, so it defaults to "Faculty"; status comes
  /// from `is_active`. The backend has no name search, so [query] filters
  /// client-side.
  Future<ApiResponse<List<Teacher>>> fetchTeachers({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Teacher>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'teacher', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) => Teacher(
                id: '${u['id']}',
                name: u['full_name'] as String? ?? '',
                department: 'Faculty',
                status: (u['is_active'] as bool? ?? true)
                    ? TeacherStatus.active
                    : TeacherStatus.onLeave,
                accent: AppColors.primary,
              ))
          .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
          .toList(),
    );
  }

  /// Live students from `/schools/{id}/users?role_code=student`. The backend
  /// user payload has no roll/grade/section, so those are blank and the
  /// grade/section filters are not applied server-side; [query] filters by name
  /// client-side.
  Future<ApiResponse<List<Student>>> fetchStudents({
    String query = '',
    String? grade,
    String? section,
  }) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Student>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'student', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) => Student(
                id: '${u['id']}',
                roll: '',
                name: u['full_name'] as String? ?? '',
                grade: '',
                section: '',
                status: (u['is_active'] as bool? ?? true)
                    ? StudentStatus.active
                    : StudentStatus.pending,
              ))
          .where((s) => q.isEmpty || s.name.toLowerCase().contains(q))
          .toList(),
    );
  }

  /// Live guardians from `/schools/{id}/users?role_code=guardian`. The backend
  /// user payload has no linked-students list, so it stays empty; [query]
  /// filters by name client-side.
  Future<ApiResponse<List<Guardian>>> fetchGuardians({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Guardian>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'guardian', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) => Guardian(
                id: '${u['id']}',
                name: u['full_name'] as String? ?? '',
                email: u['email'] as String? ?? '',
                phone: u['phone'] as String?,
                status: (u['is_active'] as bool? ?? true)
                    ? GuardianStatus.active
                    : GuardianStatus.pending,
                linkedStudents: const [],
              ))
          .where((g) => q.isEmpty || g.name.toLowerCase().contains(q))
          .toList(),
    );
  }
}
