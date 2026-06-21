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

  /// The signed-in student's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  Future<ApiResponse<AttendanceData>> fetchAttendance() {
    return _api.request<AttendanceData>(
      method: HttpMethod.get,
      path: StudentEndpoints.attendance,
      parser: (json) => AttendanceData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Live assignments from `/schools/{id}/homework/assignments` (`AssignmentOut`
  /// list). The backend has no subject name or per-student submission state, so
  /// [StudentAssignment.subject] is blank, status is "Not Started", and points
  /// come from `max_marks`. Summary counts derive from the list (none known
  /// complete).
  Future<ApiResponse<AssignmentsData>> fetchAssignments() {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: StudentEndpoints.homeworkAssignments(_sid),
      parser: (json) {
        final items = (json as List).cast<Map<String, dynamic>>().map((a) {
          final due = a['due_date'] as String?;
          return StudentAssignment(
            id: '${a['id']}',
            subject: '',
            title: a['title'] as String? ?? '',
            description: a['description'] as String? ?? '',
            dueLine: due == null ? '' : 'Due $due',
            status: StudentAssignmentStatus.notStarted,
            accent: StudentAssignmentStatus.notStarted.color,
            points: (a['max_marks'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        return AssignmentsData(
          summary: AssignmentsSummary(
            completed: 0,
            total: items.length,
            inProgress: 0,
            toDo: items.length,
          ),
          assignments: items,
        );
      },
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

  /// Live exams from `/schools/{id}/exams` (`ExamOut` list). Builds the upcoming
  /// timeline + a countdown to the soonest exam. The backend has no time or
  /// location, so those are blank and the countdown is whole-days only.
  Future<ApiResponse<ExamsData>> fetchExams() {
    return _api.request<ExamsData>(
      method: HttpMethod.get,
      path: StudentEndpoints.examsList(_sid),
      parser: (json) {
        final now = DateTime.now();
        final raw = (json as List).cast<Map<String, dynamic>>();
        final timeline = raw.map((e) {
          final date = e['start_date'] as String? ?? '';
          return UpcomingExam(
            id: '${e['id']}',
            title: e['name'] as String? ?? '',
            date: date,
            time: '',
            location: '',
            dateShort: date,
            accent: AppColors.primary,
          );
        }).toList();

        // Soonest exam with a future start date → countdown.
        final upcoming = raw
            .map((e) => DateTime.tryParse(e['start_date'] as String? ?? ''))
            .whereType<DateTime>()
            .where((d) => d.isAfter(now))
            .toList()
          ..sort();
        ExamCountdown next;
        if (upcoming.isEmpty) {
          next = const ExamCountdown(
              days: 0, hours: 0, title: '', date: '', time: '', location: '');
        } else {
          final soonest = upcoming.first;
          final match = raw.firstWhere(
              (e) => e['start_date'] == soonest.toIso8601String().split('T').first,
              orElse: () => raw.first);
          next = ExamCountdown(
            days: soonest.difference(now).inDays,
            hours: 0,
            title: match['name'] as String? ?? '',
            date: match['start_date'] as String? ?? '',
            time: '',
            location: '',
          );
        }

        final comingThisMonth = upcoming
            .where((d) => d.year == now.year && d.month == now.month)
            .length;

        return ExamsData(
          comingThisMonth: comingThisMonth,
          next: next,
          timeline: timeline,
        );
      },
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

  /// Submit an assignment via `POST /schools/{id}/homework/assignments/{id}/
  /// submissions`. Maps notes → `content` and the attachment filename →
  /// `attachment_url` (the backend stores a URL string).
  Future<ApiResponse<void>> submitAssignment(
    String id, {
    String? notes,
    String? filename,
  }) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: StudentEndpoints.submitAssignment(_sid, id),
      body: {
        'content': ?notes,
        'attachment_url': ?filename,
      },
    );
  }
}
