import 'package:shared/shared.dart';

import '../../../widgets/leave_review.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/dashboard/models/activity_item.dart';
import '../features/exams/models/exam_data.dart';
import '../features/fees/models/fee_data.dart';
import '../features/homework/models/homework_data.dart';
import '../features/meetings/models/meeting_data.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/performance/models/performance_data.dart';
import '../features/report_card/models/report_card_data.dart';
import '../features/timetable/models/timetable_data.dart';
import '../features/transport/models/transport_models.dart';
import '../shared/models/child.dart';
import 'guardian_api_service.dart';

/// Single data gateway for the Guardian module. Every Guardian controller
/// depends on this class (never on [GuardianApiService] or [ApiService]
/// directly), so business logic stays separate from network logic.
///
/// Every method reads live backend data: children come from `/me/children`
/// (the guardian↔child link), and each per-child feature reads the same
/// school-scoped resources a student uses, scoped to the child's `student_id`
/// (see [GuardianApiService] for the mapping).
class GuardianRepository {
  final GuardianApiService _api;

  GuardianRepository({GuardianApiService? api})
      : _api = api ?? GuardianApiService();

  Future<ApiResponse<List<Child>>> loadChildren() => _api.fetchChildren();

  // ------------------------------ transport ---------------------------- #

  Future<ApiResponse<MyTransportRequest>> createTransportRequest({
    required String studentId,
    required String pickupAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) =>
      _api.createTransportRequest(
        studentId: studentId, pickupAddress: pickupAddress,
        latitude: latitude, longitude: longitude, notes: notes,
      );

  Future<ApiResponse<List<MyTransportRequest>>> loadMyTransportRequests() =>
      _api.fetchMyTransportRequests();

  Future<ApiResponse<List<ActiveTrip>>> loadActiveTrips() =>
      _api.fetchActiveTrips();

  Future<ApiResponse<TripLocation>> loadTripLocation(String tripId) =>
      _api.fetchTripLocation(tripId);

  Future<ApiResponse<TripEta>> loadTripEta(String tripId) =>
      _api.fetchTripEta(tripId);

  Future<ApiResponse<List<ActivityItem>>> loadDashboardFeed(String childId) =>
      _api.fetchDashboardFeed(childId);

  Future<ApiResponse<GuardianAttendanceData>> loadAttendance(String childId) =>
      _api.fetchAttendance(childId);

  Future<ApiResponse<PerformanceData>> loadPerformance(String childId) =>
      _api.fetchPerformance(childId);

  Future<ApiResponse<FeeData>> loadFees(String childId) =>
      _api.fetchFees(childId);

  Future<ApiResponse<HomeworkData>> loadHomework(String childId) =>
      _api.fetchHomework(childId);

  Future<ApiResponse<ExamData>> loadExams(String childId) =>
      _api.fetchExams(childId);

  Future<ApiResponse<MeetingData>> loadMeetings(String childId) =>
      _api.fetchMeetings(childId);

  Future<ApiResponse<ReportCardData>> loadReportCard(String childId) =>
      _api.fetchReportCard(childId);

  Future<ApiResponse<TimetableData>> loadTimetable(String childId) =>
      _api.fetchTimetable(childId);

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _api.fetchNotifications();

  /// Marks a direct message read for the signed-in guardian.
  Future<ApiResponse<dynamic>> markMessageRead(String messageId) =>
      _api.markMessageRead(messageId);

  // ── Leave (for a child) ──
  Future<ApiResponse<List<LeaveReviewItem>>> loadMyLeave() =>
      _api.fetchMyLeave();

  Future<ApiResponse<dynamic>> submitLeave({
    required String studentId,
    String? leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) =>
      _api.submitLeave(
        studentId: studentId,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
}
