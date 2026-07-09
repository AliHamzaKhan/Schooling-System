import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../models/direct_message_item.dart';
import '../models/student_report.dart';

/// Self-contained data access for the shared Student Report feature.
///
/// Both the Headmaster and Teacher modules route into this feature (a teacher
/// drills class → section → student exactly like the headmaster), so it talks
/// to [ApiService] directly instead of depending on either module repository.
class StudentReportService {
  final ApiService _api;
  StudentReportService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  String get _sid => Get.find<AuthService>().schoolId ?? '';

  /// One student's 360-degree report (attendance, exams, assignments, quizzes,
  /// points, guardians).
  Future<ApiResponse<StudentReport>> fetchReport(String studentId) {
    return _api.request<StudentReport>(
      method: HttpMethod.get,
      path: '/schools/$_sid/reports/students/$studentId',
      parser: (json) => StudentReport.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Requests a parent-teacher meeting with the student's guardian.
  Future<ApiResponse<dynamic>> requestMeeting({
    required String title,
    required DateTime scheduledAt,
    String? guardianId,
    String? studentId,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: '/schools/$_sid/meetings',
      body: {
        'title': title,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'guardian_id': ?guardianId,
        'student_id': ?studentId,
      },
      parser: (json) => json,
    );
  }

  /// Sends a direct message (or complaint, when [kind] is 'complaint') to a
  /// guardian about a student. Persisted server-side; the guardian sees it in
  /// their alerts.
  Future<ApiResponse<dynamic>> sendDirectMessage({
    required String recipientId,
    required String body,
    String? studentId,
    String kind = 'message',
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: '/schools/$_sid/messages',
      body: {
        'recipient_id': recipientId,
        'student_id': ?studentId,
        'kind': kind,
        'body': body,
      },
      parser: (json) => json,
    );
  }

  /// The acting staff member's sent messages, optionally filtered to one
  /// student — their side of the guardian conversation.
  Future<ApiResponse<List<DirectMessageItem>>> fetchSentMessages({
    String? studentId,
  }) {
    return _api.request<List<DirectMessageItem>>(
      method: HttpMethod.get,
      path: '/schools/$_sid/messages',
      query: {'box': 'sent'},
      parser: (json) {
        final items = (json as List)
            .cast<Map<String, dynamic>>()
            .map(DirectMessageItem.fromJson)
            .toList();
        if (studentId == null || studentId.isEmpty) return items;
        return items.where((m) => m.studentId == studentId).toList();
      },
    );
  }

  /// Sections of one class (id + name), for the class → section drill-down.
  Future<ApiResponse<List<RosterEntry>>> fetchClassSections(String classId) {
    return _api.request<List<RosterEntry>>(
      method: HttpMethod.get,
      path: '/schools/$_sid/academic/classes/$classId/sections',
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((s) =>
              RosterEntry(id: '${s['id']}', name: s['name'] as String? ?? ''))
          .toList(),
    );
  }

  /// Enrolled students of one section (id + name), for the section → student
  /// drill-down. Uses the quiz roster endpoint, which resolves names.
  Future<ApiResponse<List<RosterEntry>>> fetchSectionStudents(
      String sectionId) {
    return _api.request<List<RosterEntry>>(
      method: HttpMethod.get,
      path: '/schools/$_sid/quizzes/sections/$sectionId/students',
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((s) => RosterEntry(
              id: '${s['student_id']}', name: s['name'] as String? ?? ''))
          .toList(),
    );
  }
}

/// A generic id + display-name pair used by the drill-down lists.
class RosterEntry {
  final String id;
  final String name;
  const RosterEntry({required this.id, required this.name});
}
