import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/announcements/models/announcement.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/classes/models/classes_data.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/exams/models/exams_data.dart';
import '../features/fees/models/fees_data.dart';
import '../features/guardians/models/guardian.dart';
import '../features/overview/models/overview_data.dart';
import '../features/reports/models/reports_data.dart';
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
  HeadmasterApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  /// The signed-in headmaster's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  /// Raw GET returning the decoded JSON untouched (helper for aggregate
  /// methods that combine several backend endpoints into one view-model).
  Future<ApiResponse<dynamic>> _get(String path, {Map<String, String>? query}) =>
      _api.request<dynamic>(
        method: HttpMethod.get,
        path: path,
        query: query,
        parser: (json) => json,
      );

  String get _userName =>
      Get.find<AuthService>().currentUser.value?['full_name'] as String? ?? '';

  String _money(num v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  /// Headmaster Dashboard — KPI metrics from `/reports/overview` plus recent
  /// announcements from `/communication/broadcasts`. The backend exposes no
  /// pending-approval queue, so [DashboardData.approvals] stays empty; trend
  /// percentages are not tracked server-side (default 0).
  Future<ApiResponse<DashboardData>> fetchDashboard() async {
    final ov = await _get(HeadmasterEndpoints.reportsOverview(_sid));
    if (!ov.success) return ApiResponse.fail(ov.error ?? 'Failed to load');
    final o = (ov.data as Map).cast<String, dynamic>();
    final bc = await _get(HeadmasterEndpoints.broadcasts(_sid),
        query: {'limit': '5'});
    final announcements = bc.success
        ? (bc.data as List).cast<Map<String, dynamic>>().map((m) {
            final body = m['body'] as String? ?? '';
            return RecentAnnouncementSummary.fromJson({
              'id': m['id'],
              'title': m['title'] ??
                  (body.length > 40 ? '${body.substring(0, 40)}…' : body),
              'preview': body,
              'time_ago': (m['sent_at'] ?? m['scheduled_at']) ?? '',
            });
          }).toList()
        : <RecentAnnouncementSummary>[];
    return ApiResponse.ok(DashboardData(
      greeting: _userName.isEmpty ? 'Welcome back' : 'Welcome back, $_userName',
      date: '',
      metrics: [
        DashboardMetric.fromJson(
            {'label': 'Total Students', 'value': o['students']}),
        DashboardMetric.fromJson({'label': 'Teachers', 'value': o['teachers']}),
        DashboardMetric.fromJson({'label': 'Classes', 'value': o['classes']}),
        DashboardMetric.fromJson({'label': 'Subjects', 'value': o['subjects']}),
      ],
      approvals: const [],
      announcements: announcements,
    ));
  }

  /// School Overview — identity from `/schools/{id}` and KPI pulse from
  /// `/reports/overview`. The backend has no events feed, so the Upcoming
  /// Events carousel stays empty.
  Future<ApiResponse<OverviewData>> fetchOverview() async {
    final ov = await _get(HeadmasterEndpoints.reportsOverview(_sid));
    if (!ov.success) return ApiResponse.fail(ov.error ?? 'Failed to load');
    final o = (ov.data as Map).cast<String, dynamic>();
    final sc = await _get(HeadmasterEndpoints.school(_sid));
    final s = sc.success
        ? (sc.data as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return ApiResponse.ok(OverviewData(
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
    ));
  }

  /// Attendance Overview — from `/reports/attendance` (present_rate + status
  /// counts). The backend aggregate has no per-grade breakdown, teacher
  /// attendance, or time-series trend, so those render empty.
  Future<ApiResponse<AttendanceData>> fetchAttendance(
      AttendanceRange range) async {
    final res = await _get(HeadmasterEndpoints.reportsAttendance(_sid));
    if (!res.success) return ApiResponse.fail(res.error ?? 'Failed to load');
    final a = (res.data as Map).cast<String, dynamic>();
    final counts = ((a['counts'] as Map?) ?? const {}).cast<String, dynamic>();
    final rate = ((a['present_rate'] as num?)?.toDouble() ?? 0).round();
    return ApiResponse.ok(AttendanceData(
      metrics: [
        AttendanceMetric.fromJson({'label': 'Present Rate', 'value': '$rate%'}),
        AttendanceMetric.fromJson(
            {'label': 'Present', 'value': counts['present'] ?? 0}),
        AttendanceMetric.fromJson(
            {'label': 'Absent', 'value': counts['absent'] ?? 0}),
        AttendanceMetric.fromJson(
            {'label': 'Records', 'value': a['total_records'] ?? 0}),
      ],
      studentRatePercent: rate,
      teacherRatePercent: 0,
      trendLabels: const [],
      studentTrend: const [],
      teacherTrend: const [],
      grades: const [],
    ));
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
            icon: Icons.school_outlined,
            iconColor: AppColors.primary,
            status: status,
          );
        }).toList();
        return ExamsData(
          activeExams: schedule.where((s) => s.status == ExamStatus.live).length,
          upcomingExams:
              schedule.where((s) => s.status == ExamStatus.upcoming).length,
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
  Future<ApiResponse<FeesData>> fetchFees() async {
    final fin = await _get(HeadmasterEndpoints.reportsFinance(_sid));
    if (!fin.success) return ApiResponse.fail(fin.error ?? 'Failed to load');
    final f = (fin.data as Map).cast<String, dynamic>();
    final inv = await _get(HeadmasterEndpoints.feesInvoices(_sid),
        query: {'limit': '200'});
    final overdue = inv.success
        ? (inv.data as List)
            .cast<Map<String, dynamic>>()
            .where((i) => i['is_overdue'] as bool? ?? false)
            .map((i) => OverduePayment.fromJson({
                  'id': i['id'],
                  'student_name': i['title'] ?? 'Invoice',
                  'grade': '',
                  'overdue_days': 0,
                  'amount': i['balance'] ?? 0,
                }))
            .toList()
        : <OverduePayment>[];
    final collected = (f['total_collected'] as num?)?.toDouble() ?? 0;
    final billed = (f['total_billed'] as num?)?.toDouble() ?? 0;
    final outstanding = (f['total_outstanding'] as num?)?.toDouble() ?? 0;
    final rate = (f['collection_rate'] as num?)?.toDouble() ?? 0;
    return ApiResponse.ok(FeesData(
      term: '',
      totalCollected: _money(collected),
      trendPercent: 0,
      progressPercent: rate,
      targetLabel: 'of ${_money(billed)} billed',
      outstandingAmount: _money(outstanding),
      outstandingCount: (f['overdue_count'] as num?)?.toInt() ?? 0,
      overdue: overdue,
    ));
  }

  /// Live classes from `/schools/{id}/academic/classes` (list of `ClassOut`:
  /// id, name, level). The backend exposes no per-section student counts or
  /// KPIs, so sections carry 0 students and only a "Total Classes" stat shows.
  Future<ApiResponse<ClassDirectoryData>> fetchClasses() {
    return _api.request<ClassDirectoryData>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.academicClasses(_sid),
      parser: (json) {
        final list = (json as List).cast<Map<String, dynamic>>();
        final grades = list.map((c) {
          final level = (c['level'] as num?)?.toInt() ?? 0;
          return GradeGroup(
            grade: level,
            level: _gradeLevel(level),
            sections: [
              ClassSection(
                id: '${c['id']}',
                name: c['name'] as String? ?? '',
                students: 0,
                accent: AppColors.primary,
              ),
            ],
          );
        }).toList();
        return ClassDirectoryData(
          stats: [
            ClassStat(
              label: 'Total Classes',
              value: '${list.length}',
              icon: Icons.class_outlined,
              color: AppColors.primary,
            ),
          ],
          grades: grades,
        );
      },
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
    final teacherRes = await _get(HeadmasterEndpoints.users(_sid),
        query: {'role_code': 'teacher', 'limit': '200'});
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
      final label = '${start.padRight(5).substring(0, 5)}'
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
        TimetableData(days: orderedDays, slots: orderedSlots));
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
                .map((e) => (e['average_percentage'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            exams.length;

    return ApiResponse.ok(ReportsData(
      metrics: [
        ReportMetric.fromJson(
            {'label': 'Avg Score', 'value': '${avgScore.round()}%'}),
        ReportMetric.fromJson({
          'label': 'Collection',
          'value': '${((fin['collection_rate'] as num?)?.toDouble() ?? 0).round()}%'
        }),
        ReportMetric.fromJson({
          'label': 'Attendance',
          'value': '${((att['present_rate'] as num?)?.toDouble() ?? 0).round()}%'
        }),
        ReportMetric.fromJson(
            {'label': 'Students', 'value': enr['total_students'] ?? 0}),
      ],
      currentYearScores: exams
          .map((e) => (e['average_percentage'] as num?)?.toDouble() ?? 0)
          .toList(),
      previousYearScores: const [],
      performanceLabels:
          exams.map((e) => e['name'] as String? ?? '').toList(),
      enrollmentByYear: {
        for (final c in ((enr['classes'] as List?) ?? [])
            .cast<Map<String, dynamic>>())
          '${c['class_name']}': (c['students'] as num?)?.toInt() ?? 0,
      },
    ));
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
            timestamp: (m['sent_at'] ?? m['scheduled_at']) as String? ?? '',
            title: m['title'] as String? ??
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

  /// Live teachers from `/schools/{id}/users?role_code=teacher`. The backend
  /// user payload has no department, so it defaults to "Faculty"; status comes
  /// from `is_active`. The backend has no name search, so [query] filters
  /// client-side.
  Future<ApiResponse<List<Teacher>>> fetchTeachers({String query = ''}) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Teacher>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'teacher', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) => Teacher(
                id: '${u['id']}',
                name: u['full_name'] as String? ?? '',
                department: 'Faculty',
                status: (u['is_active'] as bool? ?? true)
                    ? TeacherStatus.active
                    : TeacherStatus.onLeave,
                accent: AppColors.primary,
              ))
          .where((t) => q.isEmpty || t.name.toLowerCase().contains(q))
          .toList(),
    );
  }

  /// Live students from `/schools/{id}/users?role_code=student`. The backend
  /// user payload has no roll/grade/section, so those are blank and the
  /// grade/section filters are not applied server-side; [query] filters by name
  /// client-side.
  Future<ApiResponse<List<Student>>> fetchStudents({
    String query = '',
    String? grade,
    String? section,
  }) {
    final q = query.trim().toLowerCase();
    return _api.request<List<Student>>(
      method: HttpMethod.get,
      path: HeadmasterEndpoints.users(_sid),
      query: {'role_code': 'student', 'limit': '200'},
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((u) => Student(
                id: '${u['id']}',
                roll: '',
                name: u['full_name'] as String? ?? '',
                grade: '',
                section: '',
                status: (u['is_active'] as bool? ?? true)
                    ? StudentStatus.active
                    : StudentStatus.pending,
              ))
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
          .map((u) => Guardian(
                id: '${u['id']}',
                name: u['full_name'] as String? ?? '',
                email: u['email'] as String? ?? '',
                phone: u['phone'] as String?,
                status: (u['is_active'] as bool? ?? true)
                    ? GuardianStatus.active
                    : GuardianStatus.pending,
                linkedStudents: const [],
              ))
          .where((g) => q.isEmpty || g.name.toLowerCase().contains(q))
          .toList(),
    );
  }
}
