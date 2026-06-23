import 'package:flutter/material.dart';
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

  /// The signed-in teacher's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  Future<ApiResponse<DashboardData>> fetchDashboard() {
    return _api.request<DashboardData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.dashboard,
      parser: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Live classes from `/schools/{id}/academic/classes` (`ClassOut`: name,
  /// level). The backend exposes no per-class student counts or descriptions,
  /// so those default to 0 / empty.
  Future<ApiResponse<List<TeachingClass>>> fetchClasses() {
    return _api.request<List<TeachingClass>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.academicClasses(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((c) {
            final level = (c['level'] as num?)?.toInt();
            return TeachingClass(
              id: '${c['id']}',
              subject: c['name'] as String? ?? '',
              grade: level == null ? '' : 'Grade $level',
              description: '',
              students: 0,
              accent: AppColors.primary,
            );
          })
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

  /// Live assignments from `/schools/{id}/homework/assignments` (list of
  /// `AssignmentOut`). The backend has no per-assignment class name,
  /// submission counts, or KPI stats, so [Assignment.className] is blank,
  /// turned-in/total are 0, and the header stats are derived from the list
  /// (active = due in the future). [classFilter] is ignored (no class name to
  /// match server- or client-side).
  Future<ApiResponse<AssignmentsData>> fetchAssignments({String? classFilter}) {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.homeworkAssignments(_sid),
      parser: (json) {
        final now = DateTime.now();
        final items = (json as List).cast<Map<String, dynamic>>().map((a) {
          final due = DateTime.tryParse(a['due_date'] as String? ?? '');
          final isClosed = due != null && due.isBefore(now);
          return Assignment(
            id: '${a['id']}',
            title: a['title'] as String? ?? '',
            className: '',
            dueLabel: a['due_date'] as String? ?? '',
            status:
                isClosed ? AssignmentStatus.closed : AssignmentStatus.active,
            turnedIn: 0,
            total: 0,
            icon: Icons.assignment_outlined,
            iconAccent: AppColors.primary,
          );
        }).toList();
        final active =
            items.where((a) => a.status == AssignmentStatus.active).length;
        return AssignmentsData(
          stats: AssignmentStats(
            toGrade: 0,
            toGradeDelta: 0,
            activeCount: active,
            activeAcrossClasses: 0,
            averageTurnInRate: 0,
            averageTurnInDelta: 0,
          ),
          assignments: items,
        );
      },
    );
  }

  /// Live message threads from school broadcasts
  /// (`/schools/{id}/communication/broadcasts`, `MessageOut` list). The backend
  /// has no per-thread sender/party or read state, so every item maps to
  /// [ThreadParty.parent] with the broadcast title as the sender; `time` shows
  /// the sent/scheduled timestamp. [query]/[party] filter client-side.
  Future<ApiResponse<List<MessageThread>>> fetchMessages({
    String query = '',
    String? party,
  }) {
    final q = query.trim().toLowerCase();
    return _api.request<List<MessageThread>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.broadcasts(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((m) {
            final body = m['body'] as String? ?? '';
            return MessageThread(
              id: '${m['id']}',
              senderName: m['title'] as String? ?? 'Broadcast',
              preview: body,
              time: (m['sent_at'] ?? m['scheduled_at']) as String? ?? '',
              party: ThreadParty.parent,
            );
          })
          .where((t) =>
              q.isEmpty ||
              t.senderName.toLowerCase().contains(q) ||
              t.preview.toLowerCase().contains(q))
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
