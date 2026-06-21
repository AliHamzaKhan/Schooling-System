import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/attendance/models/attendance_data.dart';
import '../features/dashboard/models/activity_item.dart';
import '../features/exams/models/exam_data.dart';
import '../features/fees/models/fee_data.dart';
import '../features/homework/models/homework_data.dart';
import '../features/meetings/models/meeting_data.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/performance/models/performance_data.dart';
import '../shared/models/child.dart';
import 'guardian_endpoints.dart';

/// Network layer for the Guardian module. Owns every Guardian HTTP call and
/// nothing else: it builds the request through the shared [ApiService]
/// (which injects auth headers, applies the base URL, unwraps the response
/// envelope and surfaces errors), points at paths from [GuardianEndpoints],
/// and parses the payload into typed models.
///
/// Controllers never touch this class directly — they go through
/// `GuardianRepository`, which decides between this live service and mock data.
class GuardianApiService {
  final ApiService _api;
  GuardianApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  /// The signed-in guardian's school id — used by the live broadcasts feed.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  Future<ApiResponse<List<Child>>> fetchChildren() {
    return _api.request<List<Child>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.children,
      parser: (json) => (json as List)
          .map((e) => Child.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<ActivityItem>>> fetchDashboardFeed(String childId) {
    return _api.request<List<ActivityItem>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.dashboardFeed(childId),
      parser: (json) => (json as List)
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<GuardianAttendanceData>> fetchAttendance(String childId) {
    return _api.request<GuardianAttendanceData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.attendance(childId),
      parser: (json) =>
          GuardianAttendanceData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PerformanceData>> fetchPerformance(String childId) {
    return _api.request<PerformanceData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.performance(childId),
      parser: (json) => PerformanceData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<FeeData>> fetchFees(String childId) {
    return _api.request<FeeData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.fees(childId),
      parser: (json) => FeeData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<HomeworkData>> fetchHomework(String childId) {
    return _api.request<HomeworkData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.homework(childId),
      parser: (json) => HomeworkData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ExamData>> fetchExams(String childId) {
    return _api.request<ExamData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.exams(childId),
      parser: (json) => ExamData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<MeetingData>> fetchMeetings(String childId) {
    return _api.request<MeetingData>(
      method: HttpMethod.get,
      path: GuardianEndpoints.meetings(childId),
      parser: (json) => MeetingData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Live notifications from school broadcasts
  /// (`/schools/{id}/communication/broadcasts`, `MessageOut` list). The backend
  /// has no severity or per-child tagging, so every item maps to
  /// [AlertLevel.info] with no `childName`; [timeAgo] shows the sent/scheduled
  /// timestamp.
  Future<ApiResponse<List<NotificationItem>>> fetchNotifications() {
    return _api.request<List<NotificationItem>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.broadcasts(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>().map((m) {
        final body = m['body'] as String? ?? '';
        return NotificationItem(
          id: '${m['id']}',
          title: m['title'] as String? ??
              (body.length > 40 ? '${body.substring(0, 40)}…' : body),
          body: body,
          timeAgo: (m['sent_at'] ?? m['scheduled_at']) as String? ?? '',
          level: AlertLevel.info,
        );
      }).toList(),
    );
  }
}
