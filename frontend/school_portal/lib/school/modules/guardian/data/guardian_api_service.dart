import 'package:get/get.dart';
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
import '../shared/controller/guardian_session_controller.dart';
import '../shared/models/child.dart';
import 'guardian_endpoints.dart';

/// Network layer for the Guardian module. A guardian reads their linked
/// children's data through the same school-scoped resources a student uses,
/// scoped to each child's `student_id` (and section for timetable/homework).
///
/// Controllers never touch this class directly — they go through
/// `GuardianRepository`, which decides between this live service and mock data.
class GuardianApiService {
  final ApiService _api;

  GuardianApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  String get _sid => Get.find<AuthService>().schoolId ?? '';

  Future<ApiResponse<dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) => _api.request<dynamic>(
    method: HttpMethod.get,
    path: path,
    query: query,
    parser: (json) => json,
  );

  /// The active section id for a child, read from the session's children list.
  String? _sectionId(String childId) =>
      Get.isRegistered<GuardianSessionController>()
      ? Get.find<GuardianSessionController>().children
            .firstWhereOrNull((c) => c.id == childId)
            ?.sectionId
      : null;

  /// subject_id → name, for resolving homework/report-card subject labels.
  Future<Map<String, String>> _subjects() async {
    final res = await _get(GuardianEndpoints.academicSubjects(_sid));
    if (!res.success) return {};
    return {
      for (final s in (res.data as List).cast<Map<String, dynamic>>())
        '${s['id']}': s['name'] as String? ?? '',
    };
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// "2025-10-14" → "Oct 14".
  String _fmtDate(String? iso) {
    final d = DateTime.tryParse('$iso');
    return d == null ? (iso ?? '') : '${_months[d.month - 1]} ${d.day}';
  }

  /// "09:00:00" → "09:00 AM".
  String _fmtTime(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length < 2) return '';
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${h12.toString().padLeft(2, '0')}:$m $ampm';
  }

  /// Letter grade for a percentage (mirrors backend GRADE_BANDS).
  String _grade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  // ----------------------------- children ------------------------------ #

  Future<ApiResponse<List<Child>>> fetchChildren() {
    return _api.request<List<Child>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.myChildren(_sid),
      parser: (json) => (json as List)
          .map((e) => Child.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---------------------------- attendance ------------------------------ #

  /// Per-child attendance from `/students/{id}/attendance` (AttendanceRecordOut
  /// list), aggregated into the guardian summary.
  Future<ApiResponse<GuardianAttendanceData>> fetchAttendance(
    String childId,
  ) async {
    final res = await _get(GuardianEndpoints.studentAttendance(_sid, childId));
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final records = (res.data as List).cast<Map<String, dynamic>>();
    String st(Map<String, dynamic> r) => '${r['status'] ?? ''}'.toLowerCase();
    final present = records
        .where((r) => ['present', 'excused'].contains(st(r)))
        .length;
    final late = records
        .where((r) => ['late', 'early_departure'].contains(st(r)))
        .length;
    final absent = records.where((r) => st(r) == 'absent').length;
    final pct = records.isEmpty
        ? 0
        : ((present + late) * 100 / records.length).round();
    final sorted = [...records]
      ..sort(
        (a, b) =>
            '${b['attendance_date']}'.compareTo('${a['attendance_date']}'),
      );
    AttendanceStatus mapStatus(String s) => switch (s) {
      'absent' => AttendanceStatus.absent,
      'late' || 'early_departure' => AttendanceStatus.late,
      _ => AttendanceStatus.present,
    };
    return ApiResponse.ok(
      GuardianAttendanceData(
        monthlyPercent: pct,
        presentDays: present,
        absentDays: absent,
        lateDays: late,
        recent: sorted
            .take(12)
            .map(
              (r) => AttendanceRecord(
                date: _fmtDate('${r['attendance_date']}'),
                status: mapStatus(st(r)),
                note: r['remarks'] as String?,
              ),
            )
            .toList(),
      ),
    );
  }

  // ------------------------------- fees --------------------------------- #

  /// Per-child fees from `/fees/invoices?student_id=` (InvoiceOut list).
  Future<ApiResponse<FeeData>> fetchFees(String childId) async {
    final res = await _get(
      GuardianEndpoints.feesInvoices(_sid),
      query: {'student_id': childId, 'limit': '200'},
    );
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final invoices = (res.data as List).cast<Map<String, dynamic>>();
    double outstanding = 0, paid = 0;
    String? nextDue;
    final mapped = <FeeInvoice>[];
    for (final i in invoices) {
      final amount = (i['amount'] as num?)?.toDouble() ?? 0;
      final balance =
          (i['balance'] as num?)?.toDouble() ??
          (amount - ((i['amount_paid'] as num?)?.toDouble() ?? 0));
      outstanding += balance;
      paid += (i['amount_paid'] as num?)?.toDouble() ?? 0;
      final status = '${i['status']}' == 'paid'
          ? InvoiceStatus.paid
          : (i['is_overdue'] as bool? ?? false)
          ? InvoiceStatus.overdue
          : InvoiceStatus.due;
      if (status != InvoiceStatus.paid) {
        final due = '${i['due_date']}';
        if (nextDue == null || due.compareTo(nextDue) < 0) nextDue = due;
      }
      mapped.add(
        FeeInvoice(
          title: i['title'] as String? ?? 'Invoice',
          period: _fmtDate('${i['due_date']}'),
          amount: amount,
          dueDate: _fmtDate('${i['due_date']}'),
          status: status,
        ),
      );
    }
    return ApiResponse.ok(
      FeeData(
        currency: r'$',
        outstanding: outstanding,
        paidThisYear: paid,
        nextDueDate: nextDue == null ? null : _fmtDate(nextDue),
        invoices: mapped,
      ),
    );
  }

  // ----------------------------- homework ------------------------------- #

  /// Per-child homework: section assignments crossed with the child's
  /// submissions to derive each item's status.
  Future<ApiResponse<HomeworkData>> fetchHomework(String childId) async {
    final section = _sectionId(childId);
    final asgRes = await _get(
      GuardianEndpoints.homeworkAssignments(_sid),
      query: {'limit': '200', 'section_id': ?section},
    );
    if (!asgRes.success) {
      return ApiResponse.fail(asgRes.error ?? 'Failed to load');
    }
    var assignments = (asgRes.data as List).cast<Map<String, dynamic>>();
    if (section != null) {
      assignments = assignments
          .where((a) => '${a['section_id']}' == section)
          .toList();
    }
    final subRes = await _get(
      GuardianEndpoints.studentSubmissions(_sid, childId),
    );
    final submissions = <String, Map<String, dynamic>>{
      if (subRes.success)
        for (final s in (subRes.data as List).cast<Map<String, dynamic>>())
          '${s['assignment_id']}': s,
    };
    final subjects = await _subjects();
    final today = DateTime.now();
    int pending = 0, submitted = 0;
    final items = assignments.map((a) {
      final sub = submissions['${a['id']}'];
      final due = DateTime.tryParse('${a['due_date']}');
      HomeworkStatus status;
      String? grade;
      if (sub != null) {
        final ss = '${sub['status']}';
        if (ss == 'graded') {
          status = HomeworkStatus.graded;
          final m = sub['marks_obtained'];
          final max = a['max_marks'];
          if (m != null && max != null) grade = '$m/$max';
        } else {
          status = HomeworkStatus.submitted;
        }
        submitted++;
      } else if (due != null && due.isBefore(today)) {
        status = HomeworkStatus.overdue;
        pending++;
      } else {
        status = HomeworkStatus.pending;
        pending++;
      }
      return HomeworkItem(
        subject: subjects['${a['subject_id']}'] ?? '',
        title: a['title'] as String? ?? '',
        dueDate: _fmtDate('${a['due_date']}'),
        status: status,
        grade: grade,
      );
    }).toList();
    return ApiResponse.ok(
      HomeworkData(pending: pending, submitted: submitted, items: items),
    );
  }

  // ------------------------------- exams -------------------------------- #

  Future<List<Map<String, dynamic>>> _examList() async {
    final res = await _get(
      GuardianEndpoints.exams(_sid),
      query: {'limit': '100'},
    );
    return res.success ? (res.data as List).cast<Map<String, dynamic>>() : [];
  }

  bool _isCompleted(Map<String, dynamic> e) =>
      ['completed', 'published'].contains('${e['status']}'.toLowerCase());

  /// Per-child exams: upcoming (scheduled) + published results, with the child's
  /// grade pulled from each completed exam's report-card.
  Future<ApiResponse<ExamData>> fetchExams(String childId) async {
    final exams = await _examList();
    final upcoming = exams
        .where((e) => !_isCompleted(e))
        .map(
          (e) => ExamEntry(
            subject: e['name'] as String? ?? '',
            date: _fmtDate('${e['start_date']}'),
            time: '',
            room: '',
          ),
        );
    final results = <ExamEntry>[];
    for (final e in exams.where(_isCompleted)) {
      final rc = await _get(
        GuardianEndpoints.reportCard(_sid, '${e['id']}', childId),
      );
      String? label;
      if (rc.success && rc.data is Map) {
        final m = (rc.data as Map).cast<String, dynamic>();
        final pct = (m['percentage'] as num?)?.toDouble() ?? 0;
        label = '${m['grade'] ?? _grade(pct)} — ${pct.round()}%';
      }
      results.add(
        ExamEntry(
          subject: e['name'] as String? ?? '',
          date: _fmtDate('${e['start_date']}'),
          time: '',
          room: '',
          result: label,
        ),
      );
    }
    return ApiResponse.ok(
      ExamData(termLabel: '', upcoming: upcoming.toList(), results: results),
    );
  }

  // ---------------------- report card / performance --------------------- #

  /// The child's most recent completed/published exam, or null.
  Future<Map<String, dynamic>?> _latestCompletedExam() async {
    final completed = (await _examList()).where(_isCompleted).toList()
      ..sort((a, b) => '${b['start_date']}'.compareTo('${a['start_date']}'));
    return completed.isEmpty ? null : completed.first;
  }

  Future<ApiResponse<ReportCardData>> fetchReportCard(String childId) async {
    final exam = await _latestCompletedExam();
    if (exam == null) {
      return ApiResponse.ok(
        const ReportCardData(
          termLabel: 'No results yet',
          gpa: 0,
          subjects: [],
          gpaTrend: [],
        ),
      );
    }
    final rc = await _get(
      GuardianEndpoints.reportCard(_sid, '${exam['id']}', childId),
    );
    if (!rc.success) return ApiResponse.fail(rc.error ?? 'Failed to load');
    final m = (rc.data as Map).cast<String, dynamic>();
    final subjects = await _subjects();
    final lines = ((m['lines'] as List?) ?? []).cast<Map<String, dynamic>>();
    final pct = (m['percentage'] as num?)?.toDouble() ?? 0;
    return ApiResponse.ok(
      ReportCardData(
        termLabel: exam['name'] as String? ?? 'Results',
        gpa: (pct / 25).clamp(0, 4).toDouble(),
        subjects: lines.map((l) {
          final max = (l['max_marks'] as num?)?.toDouble() ?? 0;
          final got = (l['marks_obtained'] as num?)?.toDouble() ?? 0;
          final p = max == 0 ? 0.0 : got * 100 / max;
          return ReportSubject(
            subject: subjects['${l['subject_id']}'] ?? 'Subject',
            grade: _grade(p),
            percent: p.round(),
          );
        }).toList(),
        gpaTrend: [
          GpaTrendPoint(label: 'Term', gpa: (pct / 25).clamp(0, 4).toDouble()),
        ],
      ),
    );
  }

  Future<ApiResponse<PerformanceData>> fetchPerformance(String childId) async {
    final exam = await _latestCompletedExam();
    if (exam == null) {
      return ApiResponse.ok(
        const PerformanceData(
          gpa: 0,
          classRank: 0,
          classSize: 0,
          termLabel: 'No results yet',
          subjects: [],
          gpaTrend: [],
        ),
      );
    }
    final rc = await _get(
      GuardianEndpoints.reportCard(_sid, '${exam['id']}', childId),
    );
    if (!rc.success) return ApiResponse.fail(rc.error ?? 'Failed to load');
    final m = (rc.data as Map).cast<String, dynamic>();
    final subjects = await _subjects();
    final lines = ((m['lines'] as List?) ?? []).cast<Map<String, dynamic>>();
    final pct = (m['percentage'] as num?)?.toDouble() ?? 0;
    final gpa = (pct / 25).clamp(0, 4).toDouble();
    return ApiResponse.ok(
      PerformanceData(
        gpa: gpa,
        classRank: 0,
        classSize: 0,
        termLabel: exam['name'] as String? ?? 'Results',
        subjects: lines.map((l) {
          final max = (l['max_marks'] as num?)?.toDouble() ?? 0;
          final got = (l['marks_obtained'] as num?)?.toDouble() ?? 0;
          final p = max == 0 ? 0.0 : got * 100 / max;
          return SubjectGrade(
            subject: subjects['${l['subject_id']}'] ?? 'Subject',
            grade: _grade(p),
            percent: p.round(),
            deltaPercent: 0,
          );
        }).toList(),
        gpaTrend: [gpa],
      ),
    );
  }

  // ----------------------------- timetable ------------------------------ #

  /// The child's weekly timetable from `/academic/timetable`, filtered to the
  /// child's section and grouped into day columns.
  Future<ApiResponse<TimetableData>> fetchTimetable(String childId) async {
    final section = _sectionId(childId);
    final res = await _get(GuardianEndpoints.academicTimetable(_sid));
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    var slots = (res.data as List).cast<Map<String, dynamic>>();
    if (section != null) {
      slots = slots.where((s) => '${s['section_id']}' == section).toList();
    }
    final subjects = await _subjects();
    final byDay = <int, List<TimetableEntry>>{};
    for (final s in slots) {
      final dow = (s['day_of_week'] as num?)?.toInt() ?? 0;
      (byDay[dow] ??= []).add(
        TimetableEntry(
          subject: subjects['${s['subject_id']}'] ?? 'Subject',
          startTime: _fmtTime('${s['start_time']}'),
          endTime: _fmtTime('${s['end_time']}'),
          room: s['room'] as String?,
        ),
      );
    }
    final today = DateTime.now().weekday - 1; // 0=Mon
    final days = <TimetableDay>[];
    for (var i = 0; i < _weekdays.length; i++) {
      final entries = byDay[i] ?? const <TimetableEntry>[];
      if (entries.isEmpty && i > 4) continue; // hide empty weekends
      entries.sort((a, b) => a.startTime.compareTo(b.startTime));
      days.add(
        TimetableDay(
          weekday: _weekdays[i],
          dayNum: '',
          isToday: i == today,
          entries: entries,
        ),
      );
    }
    return ApiResponse.ok(TimetableData(weekLabel: 'This Week', days: days));
  }

  // ----------------------------- meetings ------------------------------- #

  /// Parent–teacher meetings for the child from `/meetings`, split into
  /// upcoming and past.
  Future<ApiResponse<MeetingData>> fetchMeetings(String childId) async {
    final res = await _get(
      GuardianEndpoints.meetings(_sid),
      query: {'limit': '100'},
    );
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final all = (res.data as List).cast<Map<String, dynamic>>().where(
      (m) => m['student_id'] == null || '${m['student_id']}' == childId,
    );
    final now = DateTime.now();
    final upcoming = <Meeting>[], past = <Meeting>[];
    for (final m in all) {
      final at = DateTime.tryParse('${m['scheduled_at']}');
      final loc = m['location'] as String?;
      final meeting = Meeting(
        teacher: m['title'] as String? ?? 'Meeting',
        subject: '',
        date: at == null ? '' : '${_months[at.month - 1]} ${at.day}',
        time: at == null
            ? ''
            : _fmtTime('${at.hour}:${at.minute.toString().padLeft(2, '0')}'),
        mode: (loc != null && loc.startsWith('http'))
            ? MeetingMode.video
            : MeetingMode.inPerson,
        status: switch ('${m['status']}'.toLowerCase()) {
          'confirmed' || 'scheduled' => MeetingStatus.confirmed,
          'completed' => MeetingStatus.completed,
          'cancelled' => MeetingStatus.cancelled,
          _ => MeetingStatus.requested,
        },
        note: m['notes'] as String?,
      );
      final isPast = at != null && at.isBefore(now);
      (isPast || meeting.status == MeetingStatus.completed ? past : upcoming)
          .add(meeting);
    }
    return ApiResponse.ok(MeetingData(upcoming: upcoming, past: past));
  }

  // --------------------------- dashboard feed --------------------------- #

  /// A light activity feed synthesised from the child's recent attendance.
  Future<ApiResponse<List<ActivityItem>>> fetchDashboardFeed(
    String childId,
  ) async {
    final res = await _get(GuardianEndpoints.studentAttendance(_sid, childId));
    if (!res.success) return ApiResponse.ok(const []);
    final records = (res.data as List).cast<Map<String, dynamic>>()
      ..sort(
        (a, b) =>
            '${b['attendance_date']}'.compareTo('${a['attendance_date']}'),
      );
    final items = records.take(8).map((r) {
      final status = '${r['status'] ?? ''}';
      final label = status.isEmpty
          ? 'Recorded'
          : '${status[0].toUpperCase()}${status.substring(1)}';
      return ActivityItem(
        kind: ActivityKind.attendance,
        title: 'Attendance: $label',
        detail: r['remarks'] as String? ?? '',
        timeAgo: _fmtDate('${r['attendance_date']}'),
      );
    }).toList();
    return ApiResponse.ok(items);
  }

  // --------------------------- notifications ---------------------------- #

  /// Notifications: school broadcasts merged with the direct messages and
  /// complaints addressed to this guardian (teacher/headmaster → guardian).
  /// Complaints surface as warnings; unread state comes from `read_at`.
  Future<ApiResponse<List<NotificationItem>>> fetchNotifications() async {
    final broadcastsRes = await _api.request<List<NotificationItem>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.broadcasts(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>().map((m) {
        final body = m['body'] as String? ?? '';
        return NotificationItem(
          id: '${m['id']}',
          title:
              m['title'] as String? ??
              (body.length > 40 ? '${body.substring(0, 40)}…' : body),
          body: body,
          timeAgo: _relative((m['sent_at'] ?? m['scheduled_at']) as String?),
          level: AlertLevel.info,
        );
      }).toList(),
    );
    final directRes = await _api.request<List<NotificationItem>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.directMessages(_sid),
      query: {'box': 'inbox'},
      parser: (json) => (json as List).cast<Map<String, dynamic>>().map((m) {
        final complaint = (m['kind'] as String?) == 'complaint';
        final sender = m['sender_name'] as String? ?? 'school';
        return NotificationItem(
          id: '${m['id']}',
          title: complaint ? 'Concern from $sender' : 'Message from $sender',
          body: m['body'] as String? ?? '',
          timeAgo: _relative(m['created_at'] as String?),
          level: complaint ? AlertLevel.warning : AlertLevel.info,
          read: m['read_at'] != null,
          directMessageId: '${m['id']}',
        );
      }).toList(),
    );
    if (!broadcastsRes.success && !directRes.success) {
      return ApiResponse.fail(
        broadcastsRes.error ?? 'Could not load notifications',
      );
    }
    // Direct messages first — they're personal and more actionable.
    return ApiResponse.ok([...?directRes.data, ...?broadcastsRes.data]);
  }

  static final _dt = DateTimeParserService();

  /// Formats an ISO timestamp as a friendly "2 hours ago"; falls back to the
  /// raw string when it can't be parsed.
  String _relative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? iso : _dt.toRelative(parsed.toLocal());
  }

  /// Marks a direct message read for the signed-in guardian.
  Future<ApiResponse<dynamic>> markMessageRead(String messageId) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: '${GuardianEndpoints.directMessages(_sid)}/$messageId/read',
      parser: (json) => json,
    );
  }

  // ─────────────────────── Leave (for a child) ───────────────────────

  Future<ApiResponse<List<LeaveReviewItem>>> fetchMyLeave() {
    return _api.request<List<LeaveReviewItem>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.leaveMine(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(LeaveReviewItem.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> submitLeave({
    required String studentId,
    String? leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: GuardianEndpoints.leaveRequests(_sid),
      body: {
        'student_id': studentId,
        'leave_type': ?leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': ?reason,
      },
      parser: (json) => json,
    );
  }

  // ------------------------------ transport ---------------------------- #

  Future<ApiResponse<MyTransportRequest>> createTransportRequest({
    required String studentId,
    required String pickupAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return _api.request<MyTransportRequest>(
      method: HttpMethod.post,
      path: GuardianEndpoints.transportRequests(_sid),
      body: {
        'student_id': studentId,
        'pickup_address': pickupAddress,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'notes': ?notes,
      },
      parser: (json) =>
          MyTransportRequest.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<MyTransportRequest>>> fetchMyTransportRequests() {
    return _api.request<List<MyTransportRequest>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.transportRequestsMine(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(MyTransportRequest.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<ActiveTrip>>> fetchActiveTrips() {
    return _api.request<List<ActiveTrip>>(
      method: HttpMethod.get,
      path: GuardianEndpoints.transportTripsActive(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ActiveTrip.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<TripLocation>> fetchTripLocation(String tripId) {
    return _api.request<TripLocation>(
      method: HttpMethod.get,
      path: GuardianEndpoints.transportTripLocation(_sid, tripId),
      parser: (json) => TripLocation.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TripEta>> fetchTripEta(String tripId) {
    return _api.request<TripEta>(
      method: HttpMethod.get,
      path: GuardianEndpoints.transportTripEta(_sid, tripId),
      parser: (json) => TripEta.fromJson(json as Map<String, dynamic>),
    );
  }
}
