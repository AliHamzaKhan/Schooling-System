import 'dart:io';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/classes/models/classes_data.dart';
import '../features/courses/models/admin_course_models.dart';
import '../../../widgets/leave_review.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/subscription_status.dart';
import '../features/exams/models/exams_data.dart';
import '../features/exams/models/exam_category.dart';
import '../features/exams/models/exam_paper.dart';
import '../features/promotion/models/promotion_models.dart';
import '../features/attendance/models/teacher_attendance_day.dart';
import '../features/fees/models/fees_data.dart';
import '../features/fees/models/student_fee_snapshot.dart';
import '../features/timetable/models/timetable_slot.dart';
import '../features/transport/models/transport_models.dart';
import '../features/guardians/models/guardian.dart';
import '../features/overview/models/overview_data.dart';
import '../features/reports/models/reports_data.dart';
import '../features/salary/models/salary_models.dart';
import '../features/settings/models/school_profile.dart';
import '../models/headmaster_workspace_context.dart';
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
  final _paymentRetries = PaymentRetryGuard();
  final _payslipRetries = PaymentRetryGuard();
  final _broadcastRetries = BroadcastRetryGuard();
  String get _broadcastScope =>
      '${Get.find<AuthService>().currentUser.value?['id'] ?? ''}/$_sid';
  Map<String, dynamic>? get pendingBroadcast =>
      _broadcastRetries.pending(_broadcastScope);
  HeadmasterApiService({ApiService? api})
    : _api = api ?? Get.find<ApiService>();

  /// The signed-in headmaster's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  /// Raw GET returning the decoded JSON untouched (helper for aggregate
  /// methods that combine several backend endpoints into one view-model).
  Future<ApiResponse<dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) => _api.request<dynamic>(
    method: HttpMethod.get,
    path: path,
    query: query,
    parser: (json) => json,
  );

  String get _userName =>
      Get.find<AuthService>().currentUser.value?['full_name'] as String? ?? '';

  static final _dt = DateTimeParserService();

  /// Capability and identity context used by the persistent desktop shell.
  /// All three reads must succeed so navigation fails closed rather than
  /// presenting modules whose effective access is unknown.
  Future<ApiResponse<HeadmasterWorkspaceContext>>
  fetchWorkspaceContext() async {
    if (_sid.isEmpty) {
      return ApiResponse.fail('School context is unavailable.');
    }
    final school = await fetchSchoolProfile();
    if (!school.success || school.data == null) {
      return ApiResponse.fail(school.error ?? 'Could not load school context.');
    }
    final overview = await _get(HeadmasterEndpoints.reportsOverview(_sid));
    if (!overview.success || overview.data is! Map) {
      return ApiResponse.fail(
        overview.error ?? 'Could not load academic session context.',
      );
    }
    final permissions = await _api.request<dynamic>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.effectivePermissions,
      parser: (json) => json,
    );
    if (!permissions.success || permissions.data is! Map) {
      return ApiResponse.fail(
        permissions.error ?? 'Could not load workspace access.',
      );
    }

    final overviewData = (overview.data as Map).cast<String, dynamic>();
    final permissionData = (permissions.data as Map).cast<String, dynamic>();
    final modules = ((permissionData['modules'] as List?) ?? const [])
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toSet();
    final session = overviewData['active_session']?.toString().trim();
    return ApiResponse.ok(
      HeadmasterWorkspaceContext(
        schoolName: school.data!.name,
        activeSession: session == null || session.isEmpty ? null : session,
        enabledModules: Set.unmodifiable(modules),
      ),
    );
  }

  /// Formats an ISO timestamp as a friendly "2 hours ago"; falls back to the
  /// raw string when it can't be parsed. Keeps announcement stamps consistent
  /// with the rest of the app.
  static String _relative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? iso : _dt.toRelative(parsed.toLocal());
  }

  int _daysOverdue(String? dueDate) {
    final due = DateTime.tryParse(dueDate ?? '');
    if (due == null) return 0;
    final today = DateTime.now();
    final days = DateTime(today.year, today.month, today.day).difference(due).inDays;
    return days < 0 ? 0 : days;
  }

  String _money(num v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  /// Headmaster Dashboard — KPI metrics from `/reports/overview` plus recent
  /// announcements from `/communication/broadcasts`, and the pending leave
  /// requests awaiting this headmaster as the approvals queue.
  Future<ApiResponse<DashboardData>> fetchDashboard() async {
    final ov = await _get(HeadmasterEndpoints.reportsOverview(_sid));
    if (!ov.success) return ApiResponse.fail(ov.error ?? 'Failed to load');
    final o = (ov.data as Map).cast<String, dynamic>();
    final bc = await _get(
      HeadmasterEndpoints.broadcasts(_sid),
      query: {'limit': '5'},
    );
    final announcements = bc.success
        ? (bc.data as List).cast<Map<String, dynamic>>().map((m) {
            final body = m['body'] as String? ?? '';
            return RecentAnnouncementSummary.fromJson({
              'id': m['id'],
              'title':
                  m['title'] ??
                  (body.length > 40 ? '${body.substring(0, 40)}…' : body),
              'preview': body,
              'time_ago': (m['sent_at'] ?? m['scheduled_at']) ?? '',
            });
          }).toList()
        : <RecentAnnouncementSummary>[];
    // The approvals queue is the real pending leave review list; a failure
    // here leaves it empty rather than failing the whole dashboard.
    final leave = await fetchLeaveReview();
    final approvals = leave.success
        ? (leave.data ?? const <LeaveReviewItem>[])
              .where((l) => l.status == 'pending')
              .take(5)
              .map(
                (l) => PendingApproval(
                  id: l.id,
                  icon: AppIcons.pendingActionsRounded,
                  title:
                      '${l.leaveType ?? 'Leave'} · ${l.startDate} – ${l.endDate}',
                  requestedBy: l.studentName ?? l.requesterName ?? '',
                ),
              )
              .toList()
        : <PendingApproval>[];
    return ApiResponse.ok(
      DashboardData(
        greeting: _userName.isEmpty
            ? 'Welcome back'
            : 'Welcome back, $_userName',
        date: '',
        metrics: [
          DashboardMetric.fromJson({
            'label': 'Total Students',
            'value': o['students'],
          }),
          DashboardMetric.fromJson({
            'label': 'Teachers',
            'value': o['teachers'],
          }),
          DashboardMetric.fromJson({'label': 'Classes', 'value': o['classes']}),
          DashboardMetric.fromJson({
            'label': 'Subjects',
            'value': o['subjects'],
          }),
        ],
        approvals: approvals,
        announcements: announcements,
      ),
    );
  }

  /// Subscription status for the Headmaster's school — drives the expiry alert
  /// (days remaining + is-expiring-soon flag).
  Future<ApiResponse<SubscriptionStatus>> fetchSubscriptionStatus() {
    return _api.request<SubscriptionStatus>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.subscriptionStatus(_sid),
      parser: (json) =>
          SubscriptionStatus.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  /// School Overview — identity from `/schools/{id}/profile` (the headmaster's
  /// self-service read; `/schools/{id}` is Super Admin only) and KPI pulse from
  /// `/reports/overview`. The backend has no events feed, so the Upcoming
  /// Events carousel stays empty.
  Future<ApiResponse<OverviewData>> fetchOverview() async {
    final ov = await _get(HeadmasterEndpoints.reportsOverview(_sid));
    if (!ov.success) return ApiResponse.fail(ov.error ?? 'Failed to load');
    final o = (ov.data as Map).cast<String, dynamic>();
    final sc = await _get(HeadmasterEndpoints.schoolProfile(_sid));
    final s = sc.success
        ? (sc.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return ApiResponse.ok(
      OverviewData(
        school: SchoolIdentity.fromJson({
          'name': s['name'] ?? '',
          'address': s['address'] ?? '',
          'principal': _userName,
        }),
        pulse: [
          PulseMetric.fromJson({'label': 'Students', 'value': o['students']}),
          PulseMetric.fromJson({'label': 'Teachers', 'value': o['teachers']}),
          PulseMetric.fromJson({'label': 'Guardians', 'value': o['guardians']}),
          PulseMetric.fromJson({'label': 'Classes', 'value': o['classes']}),
          PulseMetric.fromJson({'label': 'Sections', 'value': o['sections']}),
          PulseMetric.fromJson({'label': 'Subjects', 'value': o['subjects']}),
        ],
        events: const [],
      ),
    );
  }

  /// Attendance Overview — from `/reports/attendance` (present_rate + status
  /// counts). The backend aggregate has no per-grade breakdown, teacher
  /// attendance, or time-series trend, so those render empty.
  Future<ApiResponse<AttendanceData>> fetchAttendance(
    AttendanceRange range,
  ) async {
    final res = await _get(HeadmasterEndpoints.reportsAttendance(_sid));
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final a = (res.data as Map).cast<String, dynamic>();
    final counts = ((a['counts'] as Map?) ?? const {}).cast<String, dynamic>();
    final rate = ((a['present_rate'] as num?)?.toDouble() ?? 0).round();
    return ApiResponse.ok(
      AttendanceData(
        metrics: [
          AttendanceMetric.fromJson({
            'label': 'Present Rate',
            'value': '$rate%',
          }),
          AttendanceMetric.fromJson({
            'label': 'Present',
            'value': counts['present'] ?? 0,
          }),
          AttendanceMetric.fromJson({
            'label': 'Absent',
            'value': counts['absent'] ?? 0,
          }),
          AttendanceMetric.fromJson({
            'label': 'Records',
            'value': a['total_records'] ?? 0,
          }),
        ],
        studentRatePercent: rate,
        teacherRatePercent: 0,
        trendLabels: const [],
        studentTrend: const [],
        teacherTrend: const [],
        grades: const [],
      ),
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
            icon: AppIcons.schoolOutlined,
            iconColor: AppColors.primary,
            status: status,
          );
        }).toList();
        return ExamsData(
          activeExams: schedule
              .where((s) => s.status == ExamStatus.live)
              .length,
          upcomingExams: schedule
              .where((s) => s.status == ExamStatus.upcoming)
              .length,
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

  /// Fee Management — totals from `/reports/finance` and the overdue list from
  /// `/fees/invoices` (filtered to `is_overdue`). Invoices carry no student
  /// name/grade (only `student_id`), so overdue rows show the id-derived title;
  /// trend % is not tracked server-side.
  Future<ApiResponse<FeesData>> fetchFees({DateTime? agingAsOf}) async {
    final fin = await _get(HeadmasterEndpoints.reportsFinance(_sid));
    if (!fin.success) return ApiResponse.fail(fin.error ?? 'Failed to load');
    final f = (fin.data as Map).cast<String, dynamic>();
    final aging = await _get(
      HeadmasterEndpoints.feesAging(_sid),
      query: {if (agingAsOf != null) 'as_of': _dateOnly(agingAsOf)},
    );
    final reconciliation = await _get(
      HeadmasterEndpoints.feesReconciliation(_sid),
    );
    // The server applies the overdue filter before its 100-row page bound.
    final inv = await _get(
      HeadmasterEndpoints.feesInvoices(_sid),
      query: {'status': 'overdue', 'limit': '100'},
    );
    final overdue = inv.success
        ? (inv.data as List)
              .cast<Map<String, dynamic>>()
              .where((i) => i['is_overdue'] as bool? ?? false)
              .map(
                (i) => OverduePayment.fromJson({
                  'id': i['id'],
                  'student_id': i['student_id'],
                  'student_name': i['student_name'] ?? i['title'] ?? 'Invoice',
                  'grade': i['title'] ?? '',
                  'overdue_days': _daysOverdue(i['due_date'] as String?),
                  'amount': i['balance'] ?? 0,
                }),
              )
              .toList()
        : <OverduePayment>[];
    final collected = (f['total_collected'] as num?)?.toDouble() ?? 0;
    final billed = (f['total_billed'] as num?)?.toDouble() ?? 0;
    final outstanding = (f['total_outstanding'] as num?)?.toDouble() ?? 0;
    final rate = (f['collection_rate'] as num?)?.toDouble() ?? 0;
    return ApiResponse.ok(
      FeesData(
        term: '',
        totalCollected: _money(collected),
        progressPercent: rate,
        targetLabel: 'of ${_money(billed)} billed',
        outstandingAmount: _money(outstanding),
        outstandingCount: (f['overdue_count'] as num?)?.toInt() ?? 0,
        overdue: overdue,
        aging: aging.success && aging.data is Map
            ? ((aging.data as Map)['buckets'] as List? ?? const [])
                  .map(
                    (bucket) => FeeAgingBucket.fromJson(
                      (bucket as Map).cast<String, dynamic>(),
                    ),
                  )
                  .toList()
            : const [],
        agingAsOfDate: aging.success && aging.data is Map
            ? DateTime.tryParse(
                (aging.data as Map)['as_of_date'] as String? ?? '',
              )
            : null,
        reconciliationIssues:
            reconciliation.success && reconciliation.data is Map
            ? (((reconciliation.data as Map)['mismatch_count'] as num?)
                      ?.toInt() ??
                  0)
            : null,
      ),
    );
  }

  /// Format an API date without leaking a local time component into the
  /// school-scoped reporting boundary.
  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  /// Search students + their fee snapshot for the Record Payment / Overdue /
  /// All-Students screens. [feeStatus] may be `overdue`, `pending`, `paid`, or
  /// `no_dues`.
  Future<ApiResponse<StudentFeePage>> searchStudentFees({
    String query = '',
    int limit = 20,
    int offset = 0,
    String? classId,
    String? feeStatus,
  }) {
    return _api.request<StudentFeePage>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.feesStudents(_sid),
      query: {
        if (query.isNotEmpty) 'q': query,
        'limit': '$limit',
        'offset': '$offset',
        if (classId != null) 'class_id': classId,
        if (feeStatus != null) 'fee_status': feeStatus,
      },
      parser: (json) =>
          StudentFeePage.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  /// List every subject in the school (for the timetable editor's dropdown).
  Future<ApiResponse<List<SubjectOption>>> fetchSubjectOptions() {
    return _api.request<List<SubjectOption>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicSubjects(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(SubjectOption.fromJson)
          .toList(),
    );
  }

  /// Simple id/name list of the school's classes, for the exam timetable picker.
  Future<ApiResponse<List<PickerOption>>> fetchClassOptions() {
    return _api.request<List<PickerOption>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicClasses(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(
            (c) => PickerOption(
              id: '${c['id']}',
              label: c['name'] as String? ?? '',
            ),
          )
          .toList(),
    );
  }

  /// Timetable slots for a section (or every slot in the school if omitted).
  Future<ApiResponse<List<TimetableSlot>>> fetchTimetableSlots({
    String? sectionId,
  }) {
    return _api.request<List<TimetableSlot>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicTimetable(_sid),
      query: {if (sectionId != null) 'section_id': sectionId},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(TimetableSlot.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<TimetableSlot>> createTimetableSlot({
    required String sectionId,
    required String subjectId,
    String? teacherId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) {
    return _api.request<TimetableSlot>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.academicTimetable(_sid),
      body: {
        'section_id': sectionId,
        'subject_id': subjectId,
        if (teacherId != null) 'teacher_id': teacherId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        if (room != null) 'room': room,
      },
      parser: (json) =>
          TimetableSlot.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<ApiResponse<TimetableSlot>> updateTimetableSlot({
    required String slotId,
    String? subjectId,
    String? teacherId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
  }) {
    return _api.request<TimetableSlot>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.timetableSlot(_sid, slotId),
      body: {
        if (subjectId != null) 'subject_id': subjectId,
        if (teacherId != null) 'teacher_id': teacherId,
        if (dayOfWeek != null) 'day_of_week': dayOfWeek,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (room != null) 'room': room,
      },
      parser: (json) =>
          TimetableSlot.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<ApiResponse<dynamic>> deleteTimetableSlot(String slotId) {
    return _api.request<dynamic>(
      method: HttpMethod.delete,
      path: HeadmasterEndpoints.timetableSlot(_sid, slotId),
      parser: (json) => json,
    );
  }

  // ------------------------------ transport ---------------------------- #

  Future<ApiResponse<List<DriverRow>>> fetchDrivers() {
    return _api.request<List<DriverRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportDrivers(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(DriverRow.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<DriverRow>> createDriver({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? licenseNo,
    String? assignedVehicleId,
  }) {
    return _api.request<DriverRow>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.transportDrivers(_sid),
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (licenseNo != null) 'license_no': licenseNo,
        if (assignedVehicleId != null) 'assigned_vehicle_id': assignedVehicleId,
      },
      parser: (json) =>
          DriverRow.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<ApiResponse<DriverRow>> updateDriver({
    required String driverId,
    String? licenseNo,
    String? phone,
    String? status,
    String? assignedVehicleId,
  }) {
    return _api.request<DriverRow>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.transportDriver(_sid, driverId),
      body: {
        if (licenseNo != null) 'license_no': licenseNo,
        if (phone != null) 'phone': phone,
        if (status != null) 'status': status,
        if (assignedVehicleId != null) 'assigned_vehicle_id': assignedVehicleId,
      },
      parser: (json) =>
          DriverRow.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<ApiResponse<List<OnlineDriver>>> fetchOnlineDrivers() {
    return _api.request<List<OnlineDriver>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportDriversOnline(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(OnlineDriver.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<TransportRequestRow>>> fetchTransportRequests({
    String? status,
  }) {
    return _api.request<List<TransportRequestRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportRequests(_sid),
      query: {if (status != null) 'status': status},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(TransportRequestRow.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> approveTransportRequest(String requestId) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.transportRequestApprove(_sid, requestId),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<dynamic>> rejectTransportRequest(
    String requestId, {
    String? reason,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.transportRequestReject(_sid, requestId),
      body: {if (reason != null) 'reason': reason},
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<RouteOption>>> fetchTransportRoutes() {
    return _api.request<List<RouteOption>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportRoutes(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(RouteOption.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<RouteOption>> createTransportRoute(String name) {
    return _api.request<RouteOption>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.transportRoutes(_sid),
      body: {'name': name},
      parser: (json) =>
          RouteOption.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  Future<ApiResponse<List<AssignmentRow>>> fetchTransportAssignments() {
    return _api.request<List<AssignmentRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportAssignments(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(AssignmentRow.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> assignTransportStudent({
    required String requestId,
    required String routeId,
    required String driverId,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.transportAssignments(_sid),
      body: {
        'request_id': requestId,
        'route_id': routeId,
        'driver_id': driverId,
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<TripRow>>> fetchTransportTrips({String? status}) {
    return _api.request<List<TripRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.transportTrips(_sid),
      query: {if (status != null) 'status': status},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(TripRow.fromJson)
          .toList(),
    );
  }

  /// Teacher attendance for a given date (full roster + counts, filterable
  /// to a single status).
  Future<ApiResponse<TeacherAttendanceDay>> fetchTeacherAttendance({
    required DateTime date,
    String? status,
  }) {
    final iso =
        '${date.year.toString().padLeft(4, "0")}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
    return _api.request<TeacherAttendanceDay>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.hrTeacherAttendance(_sid),
      query: {'date': iso, if (status != null) 'status': status},
      parser: (json) =>
          TeacherAttendanceDay.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  /// Bulk mark teacher attendance for one day. Each entry upserts by
  /// `(teacher_id, date)`.
  Future<ApiResponse<dynamic>> markTeacherAttendance({
    required DateTime date,
    required List<Map<String, dynamic>> entries,
  }) {
    final iso =
        '${date.year.toString().padLeft(4, "0")}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}';
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.hrTeacherAttendance(_sid),
      body: {
        'entries': [
          for (final e in entries) {...e, 'attendance_date': iso},
        ],
      },
      parser: (json) => json,
    );
  }

  /// Paginated overdue invoices, optionally scoped to a class.
  Future<ApiResponse<List<Map<String, dynamic>>>> fetchOverdueInvoices({
    String? classId,
    int limit = 50,
    int offset = 0,
  }) {
    return _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.feesInvoices(_sid),
      query: {
        'status': 'overdue',
        if (classId != null) 'class_id': classId,
        'limit': '$limit',
        'offset': '$offset',
      },
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Live classes from `/schools/{id}/academic/classes` (list of `ClassOut`:
  /// id, name, level). The backend exposes no per-section student counts or
  /// KPIs, so sections carry 0 students and only a "Total Classes" stat shows.
  Future<ApiResponse<ClassDirectoryData>> fetchClasses() async {
    final classesRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicClasses(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!classesRes.success || classesRes.data == null) {
      return ApiResponse.fail(classesRes.error ?? 'Could not load classes');
    }
    final classes = classesRes.data!;
    final grades = <GradeGroup>[];
    var totalSections = 0;
    for (final c in classes) {
      final classId = '${c['id']}';
      final className = c['name'] as String? ?? '';
      final level = (c['level'] as num?)?.toInt() ?? 0;
      final secRes = await _api.request<List<Map<String, dynamic>>>(
        method: HttpMethod.get,
        path: HeadmasterEndpoints.classSections(_sid, classId),
        parser: (json) => (json as List).cast<Map<String, dynamic>>(),
      );
      final sections = (secRes.data ?? const <Map<String, dynamic>>[])
          .map(
            (s) => ClassSection(
              id: '${s['id']}',
              name: s['name'] as String? ?? '',
              students: 0,
              accent: AppColors.primary,
            ),
          )
          .toList();
      totalSections += sections.length;
      grades.add(
        GradeGroup(
          classId: classId,
          className: className,
          grade: level,
          level: _gradeLevel(level),
          sections: sections,
        ),
      );
    }
    return ApiResponse.ok(
      ClassDirectoryData(
        stats: [
          ClassStat(
            label: 'Total Classes',
            value: '${classes.length}',
            icon: AppIcons.classOutlined,
            color: AppColors.primary,
          ),
          ClassStat(
            label: 'Total Sections',
            value: '$totalSections',
            icon: AppIcons.gridViewRounded,
            color: AppColors.tertiary,
          ),
        ],
        grades: grades,
      ),
    );
  }

  GradeLevel _gradeLevel(int level) {
    if (level >= 9) return GradeLevel.high;
    if (level >= 6) return GradeLevel.middle;
    return GradeLevel.primary;
  }

  static const _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  /// Timetable Management — built from `/academic/timetable` (slots) with
  /// subject names resolved via `/academic/subjects` and teacher names via
  /// `/users?role_code=teacher`. Slots are grouped into rows by start–end time;
  /// each lesson is keyed by its weekday. `classLabel` shows the room (the slot
  /// references a section id, not a printable class label).
  Future<ApiResponse<TimetableData>> fetchTimetable() async {
    final res = await _get(HeadmasterEndpoints.academicTimetable(_sid));
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final slots = (res.data as List).cast<Map<String, dynamic>>();

    final subjRes = await _get(HeadmasterEndpoints.academicSubjects(_sid));
    final subjects = <String, String>{
      if (subjRes.success)
        for (final s in (subjRes.data as List).cast<Map<String, dynamic>>())
          '${s['id']}': s['name'] as String? ?? '',
    };
    final teacherRes = await _get(
      HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'teacher', 'limit': '200'},
    );
    final teachers = <String, String>{
      if (teacherRes.success)
        for (final u in (teacherRes.data as List).cast<Map<String, dynamic>>())
          '${u['id']}': u['full_name'] as String? ?? '',
    };

    final days = <String>{};
    final byTime = <String, TimeSlot>{};
    for (final s in slots) {
      final dow = (s['day_of_week'] as num?)?.toInt() ?? 0;
      final day = _dayNames[dow % 7];
      days.add(day);
      final start = '${s['start_time'] ?? ''}';
      final end = '${s['end_time'] ?? ''}';
      final label =
          '${start.padRight(5).substring(0, 5)}'
          '–${end.padRight(5).substring(0, 5)}';
      final lesson = Lesson(
        subject: subjects['${s['subject_id']}'] ?? 'Subject',
        classLabel: s['room'] as String? ?? '',
        teacher: teachers['${s['teacher_id']}'] ?? '',
        color: AppColors.primary,
      );
      final existing = byTime[label];
      byTime[label] = TimeSlot(
        label: label,
        lessons: {...?existing?.lessons, day: lesson},
      );
    }
    final orderedDays = _dayNames.where(days.contains).toList();
    final orderedSlots = byTime.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return ApiResponse.ok(
      TimetableData(days: orderedDays, slots: orderedSlots),
    );
  }

  /// Reports & Analytics — combines `/reports/academic` (per-exam averages →
  /// performance chart), `/reports/enrollment` (per-class counts → enrollment
  /// bars), `/reports/finance` and `/reports/attendance` (KPI tiles). The
  /// backend has no previous-year series, so that line stays empty.
  Future<ApiResponse<ReportsData>> fetchReports() async {
    final acaRes = await _get(HeadmasterEndpoints.reportsAcademic(_sid));
    if (!acaRes.success) return ApiResponse.fail(acaRes.error ?? 'Failed');
    final aca = (acaRes.data as Map).cast<String, dynamic>();
    final exams = ((aca['exams'] as List?) ?? []).cast<Map<String, dynamic>>();

    final enrRes = await _get(HeadmasterEndpoints.reportsEnrollment(_sid));
    final enr = enrRes.success
        ? (enrRes.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final finRes = await _get(HeadmasterEndpoints.reportsFinance(_sid));
    final fin = finRes.success
        ? (finRes.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final attRes = await _get(HeadmasterEndpoints.reportsAttendance(_sid));
    final att = attRes.success
        ? (attRes.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final avgScore = exams.isEmpty
        ? 0.0
        : exams
                  .map(
                    (e) => (e['average_percentage'] as num?)?.toDouble() ?? 0,
                  )
                  .reduce((a, b) => a + b) /
              exams.length;

    return ApiResponse.ok(
      ReportsData(
        metrics: [
          ReportMetric.fromJson({
            'label': 'Avg Score',
            'value': '${avgScore.round()}%',
          }),
          ReportMetric.fromJson({
            'label': 'Collection',
            'value':
                '${((fin['collection_rate'] as num?)?.toDouble() ?? 0).round()}%',
          }),
          ReportMetric.fromJson({
            'label': 'Attendance',
            'value':
                '${((att['present_rate'] as num?)?.toDouble() ?? 0).round()}%',
          }),
          ReportMetric.fromJson({
            'label': 'Students',
            'value': enr['total_students'] ?? 0,
          }),
        ],
        currentYearScores: exams
            .map((e) => (e['average_percentage'] as num?)?.toDouble() ?? 0)
            .toList(),
        previousYearScores: const [],
        performanceLabels: exams
            .map((e) => e['name'] as String? ?? '')
            .toList(),
        enrollmentByYear: {
          for (final c
              in ((enr['classes'] as List?) ?? []).cast<Map<String, dynamic>>())
            '${c['class_name']}': (c['students'] as num?)?.toInt() ?? 0,
        },
      ),
    );
  }

  /// Announcements Hub — from school broadcasts
  /// (`/schools/{id}/communication/broadcasts`). Audience maps to the scope pill
  /// (teachers → Teachers Only, else School-Wide); the backend has no event
  /// category or attachments. [filter] is applied client-side.
  Future<ApiResponse<List<Announcement>>> fetchAnnouncements({
    String filter = 'All Updates',
  }) {
    return _api.request<List<Announcement>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.broadcasts(_sid),
      parser: (json) {
        final items = (json as List).cast<Map<String, dynamic>>().map((m) {
          final audience = '${m['audience_type'] ?? ''}'.toLowerCase();
          final scope = audience.contains('teacher')
              ? AnnouncementScope.teachers
              : AnnouncementScope.schoolWide;
          final body = m['body'] as String? ?? '';
          return Announcement(
            id: '${m['id']}',
            scope: scope,
            timestamp: _relative(
              (m['sent_at'] ?? m['scheduled_at']) as String?,
            ),
            deliveryStatus: m['status'] as String?,
            title:
                m['title'] as String? ??
                (body.length > 40 ? '${body.substring(0, 40)}…' : body),
            body: body,
          );
        }).toList();
        if (filter == 'Teachers Only') {
          return items
              .where((a) => a.scope == AnnouncementScope.teachers)
              .toList();
        }
        if (filter == 'School-Wide') {
          return items
              .where((a) => a.scope == AnnouncementScope.schoolWide)
              .toList();
        }
        return items;
      },
    );
  }

  /// The profile photo from a `/users` payload, or null when the account has
  /// none. Registration stores it under `profile_metadata.avatar_url`; the
  /// local storage backend returns a host-relative path, which [ProfileAvatar]
  /// resolves before loading.
  static String? _avatarOf(Map<String, dynamic> user) {
    final meta = (user['profile_metadata'] as Map?)?.cast<String, dynamic>();
    final url = (meta?['avatar_url'] as String?)?.trim() ?? '';
    return url.isEmpty ? null : url;
  }

  /// Live teachers from `/schools/{id}/users?role_code=teacher`. Specialization
  /// is read from `profile_metadata.specialization` when the teacher was
  /// registered with it; older accounts fall back to blank. Status comes from
  /// `is_active`. The backend has no name search, so [query] filters
  /// client-side.
  Future<ApiResponse<List<Teacher>>> fetchTeachers({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Teacher>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'teacher', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) {
            final meta = (u['profile_metadata'] as Map?)
                ?.cast<String, dynamic>();
            final specialization =
                (meta?['specialization'] as String?)?.trim() ?? '';
            return Teacher(
              id: '${u['id']}',
              name: u['full_name'] as String? ?? '',
              avatarUrl: _avatarOf(u),
              department: specialization,
              status: (u['is_active'] as bool? ?? true)
                  ? TeacherStatus.active
                  : TeacherStatus.onLeave,
              accent: AppColors.primary,
            );
          })
          .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
          .toList(),
    );
  }

  /// Live students from `/schools/{id}/academic/students` — every student user
  /// joined to their current active enrollment, so roll number, class (grade),
  /// and section come through populated. Roll numbers are auto-assigned per
  /// section on enrollment. [query] filters by name client-side; the
  /// grade/section filters are applied client-side against the resolved values.
  Future<ApiResponse<List<Student>>> fetchStudents({
    String query = '',
    String? grade,
    String? section,
  }) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Student>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicStudents(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(
            (u) => Student(
              id: '${u['id']}',
              roll: u['roll_number'] == null ? '' : '${u['roll_number']}',
              name: u['full_name'] as String? ?? '',
              avatarUrl: (u['avatar_url'] as String?)?.trim().isEmpty ?? true
                  ? null
                  : (u['avatar_url'] as String?),
              grade: u['class_name'] as String? ?? '',
              section: u['section_name'] as String? ?? '',
              status: (u['is_active'] as bool? ?? true)
                  ? StudentStatus.active
                  : StudentStatus.pending,
            ),
          )
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
          .map(
            (u) => Guardian(
              id: '${u['id']}',
              name: u['full_name'] as String? ?? '',
              avatarUrl: _avatarOf(u),
              email: u['email'] as String? ?? '',
              phone: u['phone'] as String?,
              status: (u['is_active'] as bool? ?? true)
                  ? GuardianStatus.active
                  : GuardianStatus.pending,
              linkedStudents: const [],
            ),
          )
          .where((g) => q.isEmpty || g.name.toLowerCase().contains(q))
          .toList(),
    );
  }

  // ──────────────────────────── create actions ────────────────────────────
  // Write endpoints backing the Headmaster "add" flows. Each returns the raw
  // ApiResponse so callers can surface `error`/`fieldErrors` in the form.

  /// Create a class (grade). `level` is optional (numeric ordering).
  Future<ApiResponse<dynamic>> createClass({
    required String name,
    int? level,
    String? roomNo,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.academicClasses(_sid),
      body: {'name': name, 'level': ?level, 'room_no': ?roomNo},
      parser: (json) => json,
    );
  }

  /// Create a section under a class.
  Future<ApiResponse<dynamic>> createSection({
    required String classId,
    required String name,
    String? roomNo,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.classSections(_sid, classId),
      body: {'name': name, 'room_no': ?roomNo},
      parser: (json) => json,
    );
  }

  /// Rename a class.
  Future<ApiResponse<dynamic>> updateClass({
    required String classId,
    required String name,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.classDetail(_sid, classId),
      body: {'name': name},
      parser: (json) => json,
    );
  }

  /// Delete a class (and its sections).
  Future<ApiResponse<dynamic>> deleteClass(String classId) {
    return _api.request<dynamic>(
      method: HttpMethod.delete,
      path: HeadmasterEndpoints.classDetail(_sid, classId),
      parser: (json) => json,
    );
  }

  /// Link a student (child) to a guardian.
  Future<ApiResponse<dynamic>> linkChild({
    required String guardianId,
    required String studentId,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.guardianChildren(_sid, guardianId),
      body: {'student_id': studentId},
      parser: (json) => json,
    );
  }

  // ──────────────────────────── school settings ───────────────────────────

  /// Fetch the school profile + branding settings.
  Future<ApiResponse<SchoolProfile>> fetchSchoolProfile() {
    return _api.request<SchoolProfile>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.schoolProfile(_sid),
      parser: (json) => SchoolProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Update the school name and branding settings (logo, uniform colour,
  /// monthly fee due day). Branding fields are merged into `settings`.
  Future<ApiResponse<SchoolProfile>> updateSchoolProfile({
    required String name,
    String? logoUrl,
    String? uniformColor,
    int? feeDueDay,
    int? salaryDay,
  }) {
    return _api.request<SchoolProfile>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.schoolProfile(_sid),
      body: {
        'name': name,
        'settings': {
          'logo_url': ?logoUrl,
          'uniform_color': ?uniformColor,
          'fee_due_day': ?feeDueDay,
          'salary_day': ?salaryDay,
        },
      },
      parser: (json) => SchoolProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Create a school user (teacher / guardian / student) with one role.
  ///
  /// [phone] and [profileMetadata] are optional extended registration fields.
  /// Any keys in [profileMetadata] are stored as-is on the user record.
  Future<ApiResponse<dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    Map<String, dynamic>? profileMetadata,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.users(_sid),
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role_codes': [role],
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (profileMetadata != null && profileMetadata.isNotEmpty)
          'profile_metadata': profileMetadata,
      },
      parser: (json) => json,
    );
  }

  /// Upload an avatar image and return its public URL. Accepts either a file
  /// path (native platforms) or in-memory bytes (web).
  Future<ApiResponse<String>> uploadAvatar({
    String? filePath,
    List<int>? bytes,
    String filename = 'avatar.jpg',
    String contentType = 'image/jpeg',
  }) {
    return _api.request<String>(
      method: HttpMethod.multipart,
      path: HeadmasterEndpoints.uploads(_sid),
      body: {'folder': 'avatars'},
      files: [
        MultipartUpload(
          field: 'file',
          filename: filename,
          file: filePath == null ? null : File(filePath),
          bytes: bytes,
          contentType: contentType,
        ),
      ],
      parser: (json) => (json as Map<String, dynamic>)['url'] as String,
    );
  }

  /// Upload an image to a given [folder] and return its public URL. Used for
  /// the school uniform photo (and reusable for other image uploads).
  Future<ApiResponse<String>> uploadImage({
    required String folder,
    String? filePath,
    List<int>? bytes,
    String filename = 'image.jpg',
    String contentType = 'image/jpeg',
  }) {
    return _api.request<String>(
      method: HttpMethod.multipart,
      path: HeadmasterEndpoints.uploads(_sid),
      body: {'folder': folder},
      files: [
        MultipartUpload(
          field: 'file',
          filename: filename,
          file: filePath == null ? null : File(filePath),
          bytes: bytes,
          contentType: contentType,
        ),
      ],
      parser: (json) => (json as Map<String, dynamic>)['url'] as String,
    );
  }

  /// Enroll an existing student user into a section.
  Future<ApiResponse<dynamic>> enrollStudent({
    required String sectionId,
    required String studentId,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.sectionStudents(_sid, sectionId),
      body: {'student_id': studentId},
      parser: (json) => json,
    );
  }

  /// Record a payment against a fee invoice.
  Future<ApiResponse<dynamic>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
    DateTime? paidOn,
    String? reference,
    String? note,
    String? proofUrl,
  }) {
    final sid = _sid;
    final userId = Get.find<AuthService>().currentUser.value?['id']?.toString();
    if (sid.isEmpty || userId == null || userId.isEmpty) {
      return Future.value(
        ApiResponse.fail(
          'Sign in before recording a payment.',
          statusCode: 401,
        ),
      );
    }
    return _paymentRetries.run(
      scope: '$userId/$sid/$invoiceId',
      createPayload: () {
        final d = paidOn ?? DateTime.now();
        final iso =
            '${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
        return {
          'amount': amount,
          'method': method,
          'paid_on': iso,
          if (reference != null && reference.trim().isNotEmpty)
            'reference': reference.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (proofUrl != null && proofUrl.isNotEmpty) 'proof_url': proofUrl,
        };
      },
      send: (key, payload) => _api.request<dynamic>(
        method: HttpMethod.post,
        path: HeadmasterEndpoints.invoicePayments(sid, invoiceId),
        headers: {'Idempotency-Key': key},
        body: payload,
        parser: (json) => json,
      ),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchFinancialAdjustments({
    int limit = 20,
    int offset = 0,
    String? kind,
    String? targetType,
    String? decision,
  }) => _api.request<List<Map<String, dynamic>>>(
    method: HttpMethod.get,
    path: HeadmasterEndpoints.feesAdjustments(_sid),
    query: {
      'limit': '$limit',
      'offset': '$offset',
      if (kind != null) 'kind': kind,
      if (targetType != null) 'target_type': targetType,
      if (decision != null) 'decision': decision,
    },
    parser: (json) => (json as List)
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList(),
  );

  Future<ApiResponse<Map<String, dynamic>>> createFinancialAdjustment({
    required String kind,
    required String targetId,
    required String proposedAmount,
    required String reason,
  }) => _api.request<Map<String, dynamic>>(
    method: HttpMethod.post,
    path: HeadmasterEndpoints.feesAdjustments(_sid),
    body: {
      'kind': kind,
      'target_id': targetId,
      'proposed_amount': proposedAmount.trim(),
      'reason': reason.trim(),
    },
    parser: (json) => (json as Map).cast<String, dynamic>(),
  );

  Future<ApiResponse<Map<String, dynamic>>> decideFinancialAdjustment({
    required String adjustmentId,
    required String decision,
    required String reason,
  }) => _api.request<Map<String, dynamic>>(
    method: HttpMethod.post,
    path: HeadmasterEndpoints.feeAdjustmentDecision(_sid, adjustmentId),
    body: {'decision': decision, 'reason': reason.trim()},
    parser: (json) => (json as Map).cast<String, dynamic>(),
  );

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchBillingContacts(
    String studentId,
  ) => _api.request<List<Map<String, dynamic>>>(
    method: HttpMethod.get,
    path: HeadmasterEndpoints.billingContacts(_sid, studentId),
    parser: (json) => (json as List)
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList(),
  );

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchBillingContactCandidates(
    String studentId,
  ) => _api.request<List<Map<String, dynamic>>>(
    method: HttpMethod.get,
    path: HeadmasterEndpoints.billingContactCandidates(_sid, studentId),
    parser: (json) => (json as List)
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList(),
  );

  Future<ApiResponse<Map<String, dynamic>>> saveBillingContact({
    required String studentId,
    required String guardianId,
    String? billingEmail,
    String? billingPhone,
    String? payerReference,
    required bool isPrimary,
    String? note,
  }) => _api.request<Map<String, dynamic>>(
    method: HttpMethod.put,
    path: HeadmasterEndpoints.billingContact(_sid, studentId, guardianId),
    body: {
      'billing_email': ?billingEmail?.trim(),
      'billing_phone': ?billingPhone?.trim(),
      'payer_reference': ?payerReference?.trim(),
      'is_primary': isPrimary,
      'note': ?note?.trim(),
    },
    parser: (json) => (json as Map).cast<String, dynamic>(),
  );

  /// Compose a school broadcast (announcement) via
  /// `POST /schools/{id}/communication/broadcasts`. [audienceType] is a backend
  /// `AudienceType` value (e.g. `entire_school`, `teachers`); [channel] a
  /// backend `Channel` value (defaults to push).
  Future<ApiResponse<dynamic>> createBroadcast({
    required String body,
    String? title,
    String audienceType = 'entire_school',
    String? audienceRef,
    String channel = 'push',
  }) {
    final sid = _sid;
    if (sid.isEmpty ||
        Get.find<AuthService>().currentUser.value?['id'] == null) {
      return Future.value(
        ApiResponse.fail(
          'Sign in to your school before publishing.',
          statusCode: 401,
        ),
      );
    }
    return _broadcastRetries.run(
      scope: _broadcastScope,
      payload: {
        'channel': channel,
        'audience_type': audienceType,
        'audience_ref': ?audienceRef,
        'title': ?title,
        'body': body,
      },
      send: (key, payload) => _api.request<dynamic>(
        method: HttpMethod.post,
        path: HeadmasterEndpoints.broadcasts(sid),
        headers: {'Idempotency-Key': key},
        body: payload,
        parser: (json) => json,
      ),
    );
  }

  Future<ApiResponse<dynamic>> fetchBroadcastReview(
    String id, {
    int offset = 0,
  }) => _get(
    '${HeadmasterEndpoints.broadcasts(_sid)}/${Uri.encodeComponent(id)}/review',
    query: {'limit': '25', 'offset': '$offset'},
  );

  /// Publish (compute) results for a single exam via
  /// `POST /schools/{id}/exams/{exam_id}/results/publish`.
  Future<ApiResponse<dynamic>> publishExamResults(String examId) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.examResultsPublish(_sid, examId),
      parser: (json) => json,
    );
  }

  /// Flattened section picker options ("Grade 1 - A") built from classes +
  /// their sections. N+1 requests, acceptable for a small dropdown.
  Future<ApiResponse<List<PickerOption>>> fetchSectionOptions() async {
    final classesRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicClasses(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!classesRes.success || classesRes.data == null) {
      return ApiResponse.fail(classesRes.error ?? 'Could not load classes');
    }
    final out = <PickerOption>[];
    for (final c in classesRes.data!) {
      final classId = '${c['id']}';
      final className = c['name'] as String? ?? '';
      final secRes = await _api.request<List<Map<String, dynamic>>>(
        method: HttpMethod.get,
        path: HeadmasterEndpoints.classSections(_sid, classId),
        parser: (json) => (json as List).cast<Map<String, dynamic>>(),
      );
      if (!secRes.success || secRes.data == null) {
        return ApiResponse.fail(
          secRes.error ?? 'Could not load sections for $className',
        );
      }
      for (final s in secRes.data!) {
        out.add(
          PickerOption(
            id: '${s['id']}',
            label: '$className - ${s['name'] ?? ''}',
          ),
        );
      }
    }
    return ApiResponse.ok(out);
  }

  /// Student picker options (id + name) from the user directory.
  Future<ApiResponse<List<PickerOption>>> fetchStudentOptions() {
    return _api.request<List<PickerOption>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'student', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(
            (u) => PickerOption(
              id: '${u['id']}',
              label: u['full_name'] as String? ?? (u['email'] as String? ?? ''),
            ),
          )
          .toList(),
    );
  }

  // ──────────────────────────── salary / HR ───────────────────────────────

  /// Teachers merged with their staff/salary profiles (if any).
  Future<ApiResponse<List<SalaryStaff>>> fetchSalaryStaff() async {
    final teachersRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'teacher', 'limit': '200'},
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!teachersRes.success || teachersRes.data == null) {
      return ApiResponse.fail(teachersRes.error ?? 'Could not load teachers');
    }
    final staffRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.hrStaff(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final byUser = <String, Map<String, dynamic>>{
      for (final p in staffRes.data ?? const <Map<String, dynamic>>[])
        '${p['user_id']}': p,
    };
    final staff = teachersRes.data!.map((u) {
      final uid = '${u['id']}';
      final profile = byUser[uid];
      return SalaryStaff(
        userId: uid,
        name: u['full_name'] as String? ?? '',
        email: u['email'] as String? ?? '',
        profileId: profile == null ? null : '${profile['id']}',
        designation: profile?['designation'] as String?,
        baseSalary: (profile?['base_salary'] as num?)?.toDouble(),
      );
    }).toList();
    return ApiResponse.ok(staff);
  }

  /// Create a staff/salary profile for a user.
  Future<ApiResponse<dynamic>> createStaffProfile({
    required String userId,
    required String designation,
    required double baseSalary,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.hrStaff(_sid),
      body: {
        'user_id': userId,
        'designation': designation,
        'base_salary': baseSalary,
      },
      parser: (json) => json,
    );
  }

  /// Update an existing staff/salary profile.
  Future<ApiResponse<dynamic>> updateStaffProfile({
    required String profileId,
    required String designation,
    required double baseSalary,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.hrStaffDetail(_sid, profileId),
      body: {'designation': designation, 'base_salary': baseSalary},
      parser: (json) => json,
    );
  }

  /// Generate a payslip for a staff profile for a given month/year.
  Future<ApiResponse<PayslipRow>> generatePayslip({
    required String profileId,
    required int month,
    required int year,
    double allowances = 0,
    double deductions = 0,
    bool deductAbsences = false,
  }) {
    return _api.request<PayslipRow>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.hrStaffPayslips(_sid, profileId),
      body: {
        'period_month': month,
        'period_year': year,
        'allowances': allowances,
        'deductions': deductions,
        'deduct_absences': deductAbsences,
      },
      parser: (json) =>
          PayslipRow.fromJson((json as Map).cast<String, dynamic>()),
    );
  }

  /// Monthly attendance roll-up for one teacher + the absence deduction a
  /// payslip would apply. Powers the Generate Payslip screen.
  Future<ApiResponse<MonthlyAttendanceSummary>> fetchTeacherMonthlyAttendance({
    required String teacherId,
    required int month,
    required int year,
  }) {
    return _api.request<MonthlyAttendanceSummary>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.hrTeacherAttendanceSummary(_sid, teacherId),
      query: {'month': '$month', 'year': '$year'},
      parser: (json) => MonthlyAttendanceSummary.fromJson(
        (json as Map).cast<String, dynamic>(),
      ),
    );
  }

  /// List payslips across staff.
  Future<ApiResponse<List<PayslipRow>>> fetchPayslips() {
    return _api.request<List<PayslipRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.hrPayslips(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(PayslipRow.fromJson)
          .toList(),
    );
  }

  /// Mark a payslip as paid.
  /// Retrying after a lost response reuses the same request key, so the
  /// server answers with the original result instead of "already paid".
  Future<ApiResponse<dynamic>> markPayslipPaid(String payslipId) {
    final sid = _sid;
    return _payslipRetries.run(
      scope: '$sid/$payslipId',
      createPayload: () => const {},
      send: (key, _) => _api.request<dynamic>(
        method: HttpMethod.post,
        path: HeadmasterEndpoints.hrPayslipPay(sid, payslipId),
        headers: {'Idempotency-Key': key},
        parser: (json) => json,
      ),
    );
  }

  // ─────────────────────── Courses (authoring) ───────────────────────

  // ── Exam categories (terms) ──
  Future<ApiResponse<List<ExamCategory>>> fetchExamCategories() {
    return _api.request<List<ExamCategory>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.examCategories(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ExamCategory.fromJson)
          .toList(),
    );
  }

  static String? _ymd(DateTime? d) =>
      d == null ? null : d.toIso8601String().split('T').first;

  Future<ApiResponse<dynamic>> createExamCategory(
    String name, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.examCategories(_sid),
      body: {
        'name': name,
        if (startDate != null) 'start_date': _ymd(startDate),
        if (endDate != null) 'end_date': _ymd(endDate),
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<dynamic>> updateExamCategory(
    String id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: HeadmasterEndpoints.examCategory(_sid, id),
      body: {
        if (name != null) 'name': name,
        if (startDate != null) 'start_date': _ymd(startDate),
        if (endDate != null) 'end_date': _ymd(endDate),
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<dynamic>> announceExamCategory(String id) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.examCategoryAnnounce(_sid, id),
      body: const {},
      parser: (json) => json,
    );
  }

  Future<ApiResponse<dynamic>> deleteExamCategory(String id) {
    return _api.request<dynamic>(
      method: HttpMethod.delete,
      path: HeadmasterEndpoints.examCategory(_sid, id),
      parser: (json) => json,
    );
  }

  // ── Exam timetable: create a per-class exam under a category, then add
  //    subject papers each with a date + optional time. ──
  Future<ApiResponse<String>> createExam({
    required String classId,
    required String name,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.request<String>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.examsList(_sid),
      body: {
        'class_id': classId,
        'name': name,
        if (categoryId != null) 'category_id': categoryId,
        if (startDate != null) 'start_date': _ymd(startDate),
        if (endDate != null) 'end_date': _ymd(endDate),
      },
      parser: (json) => '${(json as Map<String, dynamic>)['id']}',
    );
  }

  Future<ApiResponse<List<ExamPaper>>> fetchExamPapers(String examId) {
    return _api.request<List<ExamPaper>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.examPapers(_sid, examId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ExamPaper.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<ExamPaper>> addExamPaper({
    required String examId,
    required String subjectId,
    required double maxMarks,
    required double passMarks,
    DateTime? examDate,
    String? examTime,
  }) {
    return _api.request<ExamPaper>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.examPapers(_sid, examId),
      body: {
        'subject_id': subjectId,
        'max_marks': maxMarks,
        'pass_marks': passMarks,
        if (examDate != null) 'exam_date': _ymd(examDate),
        if (examTime != null && examTime.isNotEmpty) 'exam_time': examTime,
      },
      parser: (json) => ExamPaper.fromJson(json as Map<String, dynamic>),
    );
  }

  // ── Exam list (for the promotion picker) ──
  Future<ApiResponse<List<ExamListItem>>> fetchExamList() {
    return _api.request<List<ExamListItem>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.examsList(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ExamListItem.fromJson)
          .toList(),
    );
  }

  // ── Promotion flow ──
  Future<ApiResponse<List<PromotionPreviewRow>>> fetchPromotionPreview(
    String examId,
  ) {
    return _api.request<List<PromotionPreviewRow>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.promotionsPreview(_sid),
      query: {'exam_id': examId},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(PromotionPreviewRow.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> applyPromotions({
    required String examId,
    required List<Map<String, dynamic>> items,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.promotions(_sid),
      body: {'exam_id': examId, 'items': items},
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<AdminCourse>>> fetchCourses() {
    return _api.request<List<AdminCourse>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.courses(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(AdminCourse.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> createCourse({
    required String title,
    String? subject,
    String? description,
    String? sectionId,
    String? subjectId,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.courses(_sid),
      body: {
        'title': title,
        'subject': ?subject,
        'description': ?description,
        'section_id': ?sectionId,
        'subject_id': ?subjectId,
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<AdminBook>>> fetchBooks(String courseId) {
    return _api.request<List<AdminBook>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.courseBooks(_sid, courseId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(AdminBook.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> createBook({
    required String courseId,
    required String title,
    String? description,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.courseBooks(_sid, courseId),
      body: {'title': title, 'description': ?description},
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<AdminChapter>>> fetchChapters(String bookId) {
    return _api.request<List<AdminChapter>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.bookChapters(_sid, bookId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(AdminChapter.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> createChapter({
    required String bookId,
    required String title,
    required String content,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.bookChapters(_sid, bookId),
      body: {'title': title, 'content': content},
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<AdminNote>>> fetchNotes(String courseId) {
    return _api.request<List<AdminNote>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.courseNotes(_sid, courseId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(AdminNote.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> createNote({
    required String courseId,
    required String title,
    required String content,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.courseNotes(_sid, courseId),
      body: {'title': title, 'content': content},
      parser: (json) => json,
    );
  }

  // ─────────────────────── School info (authoring) ───────────────────────

  Future<ApiResponse<Map<String, dynamic>>> fetchSchoolInfo() {
    return _api.request<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.schoolInfo(_sid),
      parser: (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  Future<ApiResponse<dynamic>> saveSchoolInfo({
    String? about,
    List<Map<String, dynamic>>? achievements,
    String? uniformImageUrl,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.put,
      path: HeadmasterEndpoints.schoolInfo(_sid),
      body: {
        'about': ?about,
        'achievements': ?achievements,
        'uniform_image_url': ?uniformImageUrl,
      },
      parser: (json) => json,
    );
  }

  // ─────────────────────── Leave review ───────────────────────

  Future<ApiResponse<List<LeaveReviewItem>>> fetchLeaveReview() {
    return _api.request<List<LeaveReviewItem>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.leaveForReview(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(LeaveReviewItem.fromJson)
          .toList(),
    );
  }

  /// Notifies guardians of every student with outstanding fees.
  Future<ApiResponse<int>> sendFeeReminders() {
    return _api.request<int>(
      method: HttpMethod.post,
      path: HeadmasterEndpoints.feesSendReminders(_sid),
      parser: (json) => ((json as Map)['notified_students'] as num?)?.toInt() ?? 0,
    );
  }

  Future<ApiResponse<dynamic>> reviewLeave({
    required String leaveId,
    required bool approve,
    String? note,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: approve
          ? HeadmasterEndpoints.leaveApprove(_sid, leaveId)
          : HeadmasterEndpoints.leaveReject(_sid, leaveId),
      body: {'note': ?note},
      parser: (json) => json,
    );
  }
}

/// A generic id/label pair for dropdown pickers in the create flows.
class PickerOption {
  final String id;
  final String label;
  const PickerOption({required this.id, required this.label});
}
