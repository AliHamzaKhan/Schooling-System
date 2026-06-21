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
  final _notificationMock = NotificationRepository();

  GuardianRepository({GuardianApiService? api})
      : _api = api ?? GuardianApiService();

  /// When true, methods return bundled mock data instead of hitting the API.
  ///
  /// Stays true for children + all per-child features: the backend has NO
  /// guardian↔child linkage or per-child guardian endpoints, so they cannot be
  /// wired. Only [loadNotifications] maps (school broadcasts).
  static const bool _useMock = true;

  /// Guardian-wide notifications are wired live to school broadcasts. Flip to
  /// false to revert to mock.
  static const bool _liveNotifications = true;

  Future<ApiResponse<List<Child>>> loadChildren() async {
    if (!_useMock) return _api.fetchChildren();
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
      _useMock ? _dashboardMock.loadFeed(childId) : _api.fetchDashboardFeed(childId);

  Future<ApiResponse<GuardianAttendanceData>> loadAttendance(String childId) =>
      _useMock ? _attendanceMock.load(childId) : _api.fetchAttendance(childId);

  Future<ApiResponse<PerformanceData>> loadPerformance(String childId) =>
      _useMock ? _performanceMock.load(childId) : _api.fetchPerformance(childId);

  Future<ApiResponse<FeeData>> loadFees(String childId) =>
      _useMock ? _feeMock.load(childId) : _api.fetchFees(childId);

  Future<ApiResponse<HomeworkData>> loadHomework(String childId) =>
      _useMock ? _homeworkMock.load(childId) : _api.fetchHomework(childId);

  Future<ApiResponse<ExamData>> loadExams(String childId) =>
      _useMock ? _examMock.load(childId) : _api.fetchExams(childId);

  Future<ApiResponse<MeetingData>> loadMeetings(String childId) =>
      _useMock ? _meetingMock.load(childId) : _api.fetchMeetings(childId);

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _liveNotifications ? _api.fetchNotifications() : _notificationMock.load();
}
