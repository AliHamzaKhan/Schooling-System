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

  /// The signed-in student's own user id (attendance records key on users.id).
  String get _uid =>
      Get.find<AuthService>().currentUser.value?['id']?.toString() ?? '';

  static const _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  /// Live attendance from `/schools/{id}/students/{my_user_id}/attendance`
  /// (list of `AttendanceRecordOut`). The backend returns raw daily records, so
  /// the view-model is aggregated client-side: monthly average = (present+late)
  /// / total, the week strip = the last 7 records (late counts as a half bar),
  /// recent absences and late marks come straight from the records. The backend
  /// has no previous-period figure, so `deltaPercent` is 0 and late `minutes`
  /// are unknown (0).
  Future<ApiResponse<AttendanceData>> fetchAttendance() async {
    final res = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: StudentEndpoints.studentAttendance(_sid, _uid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final records = res.data ?? [];
    String statusOf(Map<String, dynamic> r) =>
        (r['status'] as String? ?? '').toLowerCase();
    double ratioOf(String s) =>
        s == 'present' || s == 'excused' ? 1 : (s == 'late' ? 0.5 : 0);

    final present =
        records.where((r) => ['present', 'late', 'excused'].contains(statusOf(r)));
    final monthlyAverage =
        records.isEmpty ? 0 : (present.length * 100 / records.length).round();

    final sorted = [...records]..sort((a, b) =>
        '${a['attendance_date']}'.compareTo('${b['attendance_date']}'));
    final week = sorted.length <= 7 ? sorted : sorted.sublist(sorted.length - 7);

    return ApiResponse.ok(AttendanceData(
      monthlyAverage: monthlyAverage,
      deltaPercent: 0,
      week: week.map((r) {
        final date = DateTime.tryParse('${r['attendance_date']}');
        final label =
            date == null ? '' : _weekdayNames[(date.weekday - 1) % 7];
        return DayBar(label, ratioOf(statusOf(r)));
      }).toList(),
      recentAbsences: sorted
          .where((r) => statusOf(r) == 'absent')
          .map((r) => '${r['attendance_date']}')
          .toList()
          .reversed
          .take(5)
          .toList(),
      lateMarks: sorted
          .where((r) => statusOf(r) == 'late')
          .map((r) => LateMark(
              date: '${r['attendance_date']}',
              period: '',
              minutes: 0))
          .toList()
          .reversed
          .take(5)
          .toList(),
    ));
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

  /// Live notifications from school broadcasts
  /// (`/schools/{id}/communication/broadcasts`, `MessageOut` list). The backend
  /// has no per-student read state or category, so every item maps to
  /// [NotificationKind.announcement] and `unread` defaults false; `timeAgo`
  /// shows the sent/scheduled timestamp.
  Future<ApiResponse<List<NotificationItem>>> fetchNotifications() {
    return _api.request<List<NotificationItem>>(
      method: HttpMethod.get,
      path: StudentEndpoints.broadcasts(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>().map((m) {
        final body = m['body'] as String? ?? '';
        return NotificationItem(
          id: '${m['id']}',
          title: m['title'] as String? ??
              (body.length > 40 ? '${body.substring(0, 40)}…' : body),
          body: body,
          timeAgo: (m['sent_at'] ?? m['scheduled_at']) as String? ?? '',
          kind: NotificationKind.announcement,
        );
      }).toList(),
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
