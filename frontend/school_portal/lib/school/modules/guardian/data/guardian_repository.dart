import 'package:shared/shared.dart';

import '../features/attendance/models/attendance_data.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/dashboard/models/activity_item.dart';
import '../features/dashboard/models/dashboard_repository.dart';
import '../features/exams/models/exam_data.dart';
import '../features/exams/models/exam_repository.dart';
import '../features/fees/models/fee_data.dart';
import '../features/fees/models/fee_repository.dart';
import '../features/homework/models/homework_data.dart';
import '../features/homework/models/homework_repository.dart';
import '../features/meetings/models/meeting_data.dart';
import '../features/meetings/models/meeting_repository.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/notifications/models/notification_repository.dart';
import '../features/performance/models/performance_data.dart';
import '../features/performance/models/performance_repository.dart';
import '../features/report_card/models/report_card_data.dart';
import '../features/report_card/models/report_card_repository.dart';
import '../features/timetable/models/timetable_data.dart';
import '../features/timetable/models/timetable_repository.dart';
import '../shared/models/child.dart';
import 'guardian_api_service.dart';

/// Single data gateway for the Guardian module. Every Guardian controller
/// depends on this class (never on [GuardianApiService] or [ApiService]
/// directly), so business logic stays separate from network logic.
///
/// Flip [_useMock] to `false` to route every method through the live
/// [GuardianApiService]; while `true` the methods return the bundled mock
/// fixtures so the UI works before the backend exists. The mock branch reuses
/// the per-feature `*_repository.dart` fixtures as internal data sources — they
/// are no longer referenced by controllers.
class GuardianRepository {
  final GuardianApiService _api;

  // Mock fixture sources (used only while [_useMock] is true).
  final _dashboardMock = GuardianDashboardRepository();
  final _attendanceMock = GuardianAttendanceRepository();
  final _performanceMock = PerformanceRepository();
  final _feeMock = FeeRepository();
  final _homeworkMock = HomeworkRepository();
  final _examMock = ExamRepository();
  final _meetingMock = MeetingRepository();
  final _reportCardMock = ReportCardRepository();
  final _timetableMock = TimetableRepository();
  final _notificationMock = NotificationRepository();

  GuardianRepository({GuardianApiService? api})
      : _api = api ?? GuardianApiService();

  /// Every Guardian feature is now wired to live backend data: children come
  /// from `/me/children` (the guardian↔child link), and each per-child feature
  /// reads the same school-scoped resources a student uses, scoped to the
  /// child's `student_id` (see [GuardianApiService] for the mapping + losses).
  /// The bundled mock fixtures remain only as the `false`-branch fallback for
  /// each flag below.
  static const bool _live = true;
  static const bool _liveNotifications = true;

  Future<ApiResponse<List<Child>>> loadChildren() async {
    if (_live) return _api.fetchChildren();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_childrenMock);
  }

  static const _childrenMock = <Child>[
    Child(
      id: 'c1',
      name: 'Aanya Khan',
      grade: 'Grade 5 — Section B',
      attendancePercent: 96,
      gpa: 3.8,
      pendingHomework: 2,
      feesDue: false,
    ),
    Child(
      id: 'c2',
      name: 'Zayan Khan',
      grade: 'Grade 2 — Section A',
      attendancePercent: 88,
      gpa: 3.4,
      pendingHomework: 1,
      feesDue: true,
    ),
  ];

  Future<ApiResponse<List<ActivityItem>>> loadDashboardFeed(String childId) =>
      _live ? _api.fetchDashboardFeed(childId) : _dashboardMock.loadFeed(childId);

  Future<ApiResponse<GuardianAttendanceData>> loadAttendance(String childId) =>
      _live ? _api.fetchAttendance(childId) : _attendanceMock.load(childId);

  Future<ApiResponse<PerformanceData>> loadPerformance(String childId) =>
      _live ? _api.fetchPerformance(childId) : _performanceMock.load(childId);

  Future<ApiResponse<FeeData>> loadFees(String childId) =>
      _live ? _api.fetchFees(childId) : _feeMock.load(childId);

  Future<ApiResponse<HomeworkData>> loadHomework(String childId) =>
      _live ? _api.fetchHomework(childId) : _homeworkMock.load(childId);

  Future<ApiResponse<ExamData>> loadExams(String childId) =>
      _live ? _api.fetchExams(childId) : _examMock.load(childId);

  Future<ApiResponse<MeetingData>> loadMeetings(String childId) =>
      _live ? _api.fetchMeetings(childId) : _meetingMock.load(childId);

  Future<ApiResponse<ReportCardData>> loadReportCard(String childId) =>
      _live ? _api.fetchReportCard(childId) : _reportCardMock.load(childId);

  Future<ApiResponse<TimetableData>> loadTimetable(String childId) =>
      _live ? _api.fetchTimetable(childId) : _timetableMock.load(childId);

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _liveNotifications ? _api.fetchNotifications() : _notificationMock.load();

  /// Marks a direct message read for the signed-in guardian.
  Future<ApiResponse<dynamic>> markMessageRead(String messageId) =>
      _api.markMessageRead(messageId);
}
