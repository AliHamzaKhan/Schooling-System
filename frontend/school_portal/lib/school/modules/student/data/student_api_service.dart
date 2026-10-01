import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/courses/models/course_models.dart';
import '../features/leave/models/leave_models.dart';
import '../features/school_info/models/school_info_models.dart';
import '../features/transport/models/transport_models.dart';
import '../features/exams/models/exam.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/results/models/exam_result.dart';
import '../features/results/models/report_card.dart';
import '../features/timetable/models/timetable_data.dart';
import '../features/quiz/models/quiz_models.dart';
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

  static final _dt = DateTimeParserService();

  /// Formats an ISO timestamp as a friendly "2 hours ago"; falls back to the
  /// raw string when it can't be parsed. Keeps notification stamps consistent
  /// with the rest of the app.
  static String _relative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? iso : _dt.toRelative(parsed.toLocal());
  }

  static const _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];

  /// Live attendance from `/schools/{id}/students/{my_user_id}/attendance`
  /// (list of `AttendanceRecordOut`). The backend returns raw daily records, so
  /// the view-model is aggregated client-side: monthly average = (present+late)
  /// / total, the week strip = the last 7 records (late counts as a half bar),
  /// recent absences and late marks come straight from the records. The backend
  /// has no previous-period figure, so `deltaPercent` is null (not shown) and late `minutes`
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
  /// Maps a raw homework `AssignmentListOut` row into the student-facing
  /// [StudentAssignment] (folds `my_submission.status` into a simple
  /// submitted / not-started flag). Shared by the list and single-item fetches
  /// so both render identically.
  static StudentAssignment _assignmentFromRow(Map<String, dynamic> a) {
    final due = a['due_date'] as String?;
    final sub = a['my_submission'] as Map<String, dynamic>?;
    final submission =
        sub == null ? null : StudentSubmission.fromJson(sub);
    final status = switch (submission?.status) {
      'submitted' || 'late' || 'graded' || 'approved' =>
        StudentAssignmentStatus.submitted,
      _ => StudentAssignmentStatus.notStarted,
    };
    return StudentAssignment(
      id: '${a['id']}',
      subject: a['subject_name'] as String? ?? '',
      title: a['title'] as String? ?? '',
      description: a['description'] as String? ?? '',
      dueLine: due == null ? '' : 'Due $due',
      status: status,
      accent: status.color,
      points: (a['max_marks'] as num?)?.toInt() ?? 0,
      submission: submission,
    );
  }

  Future<ApiResponse<AssignmentsData>> fetchAssignments() {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: StudentEndpoints.homeworkAssignments(_sid),
      parser: (json) {
        final items = (json as List)
            .cast<Map<String, dynamic>>()
            .map(_assignmentFromRow)
            .toList();
        final completed = items
            .where((i) => i.status == StudentAssignmentStatus.submitted)
            .length;
        return AssignmentsData(
          summary: AssignmentsSummary(
            completed: completed,
            total: items.length,
            inProgress: 0,
            toDo: items.length - completed,
          ),
          assignments: items,
        );
      },
    );
  }

  Future<ApiResponse<StudentAssignment>> fetchAssignment(String id) {
    return _api.request<StudentAssignment>(
      method: HttpMethod.get,
      path: StudentEndpoints.homeworkAssignment(_sid, id),
      parser: (json) => _assignmentFromRow(json as Map<String, dynamic>),
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
          final diff = soonest.difference(now);
          next = ExamCountdown(
            days: diff.inDays,
            hours: diff.inHours % 24,
            minutes: diff.inMinutes % 60,
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

  /// Papers scheduled for one exam, from `/schools/{id}/exams/{exam_id}/papers`
  /// (`ExamSubjectOut`: subject_id, max/pass marks, exam_date). Subject names are
  /// resolved via `/academic/subjects`.
  Future<ApiResponse<List<ExamPaper>>> fetchExamPapers(String examId) async {
    final papersRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: StudentEndpoints.examPapers(_sid, examId),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!papersRes.success) {
      return ApiResponse.fail(papersRes.error ?? 'Failed to load exam details');
    }
    final subjRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: StudentEndpoints.academicSubjects(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final names = <String, String>{
      if (subjRes.success)
        for (final s in subjRes.data ?? const <Map<String, dynamic>>[])
          '${s['id']}': s['name'] as String? ?? '',
    };
    final papers = (papersRes.data ?? const <Map<String, dynamic>>[])
        .map((p) => ExamPaper(
              subject: names['${p['subject_id']}'] ?? 'Subject',
              date: p['exam_date'] as String? ?? '',
              maxMarks: (p['max_marks'] as num?)?.toDouble() ?? 0,
              passMarks: (p['pass_marks'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
    return ApiResponse.ok(papers);
  }

  /// The student's own published exam results (across exams), for the results
  /// screen. Scoped to their user id server-side via `verify_student_access`.
  Future<ApiResponse<List<ExamResultItem>>> fetchExamResults() {
    return _api.request<List<ExamResultItem>>(
      method: HttpMethod.get,
      path: StudentEndpoints.studentExamResults(_sid, _uid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ExamResultItem.fromJson)
          .toList(),
    );
  }

  /// The student's per-subject report card for one exam. Subject names are
  /// resolved via `/academic/subjects`; the exam name comes from the caller.
  Future<ApiResponse<ReportCard>> fetchReportCard(String examId) async {
    final rcRes = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: StudentEndpoints.studentReportCard(_sid, examId, _uid),
      parser: (json) => (json as Map<String, dynamic>),
    );
    if (!rcRes.success || rcRes.data == null) {
      return ApiResponse.fail(rcRes.error ?? 'Could not load report card');
    }
    final rc = rcRes.data!;
    final subjRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: StudentEndpoints.academicSubjects(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    final names = <String, String>{
      if (subjRes.success)
        for (final s in subjRes.data ?? const <Map<String, dynamic>>[])
          '${s['id']}': s['name'] as String? ?? '',
    };
    final lines = ((rc['lines'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((l) => ReportCardLine(
              subject: names['${l['subject_id']}'] ?? 'Subject',
              maxMarks: (l['max_marks'] as num?)?.toDouble() ?? 0,
              marksObtained: (l['marks_obtained'] as num?)?.toDouble(),
              isAbsent: l['is_absent'] as bool? ?? false,
              passed: l['passed'] as bool? ?? false,
            ))
        .toList();
    return ApiResponse.ok(ReportCard(
      totalMarks: (rc['total_marks'] as num?)?.toDouble() ?? 0,
      maxTotal: (rc['max_total'] as num?)?.toDouble() ?? 0,
      percentage: (rc['percentage'] as num?)?.toDouble() ?? 0,
      grade: rc['grade'] as String? ?? '',
      status: rc['status'] as String? ?? '',
      published: rc['published'] as bool? ?? false,
      lines: lines,
    ));
  }

  /// The student's own weekly timetable, grouped by weekday (empty weekends
  /// hidden). Times come back as "HH:MM"; today's column is flagged.
  Future<ApiResponse<List<TimetableDay>>> fetchTimetable() {
    return _api.request<List<TimetableDay>>(
      method: HttpMethod.get,
      path: StudentEndpoints.studentTimetable(_sid, _uid),
      parser: (json) {
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final today = DateTime.now().weekday - 1; // 0=Mon
        String hhmm(String? t) =>
            (t != null && t.length >= 5) ? t.substring(0, 5) : (t ?? '');
        final byDay = <int, List<TimetablePeriod>>{};
        for (final s in (json as List).cast<Map<String, dynamic>>()) {
          final dow = (s['day_of_week'] as num?)?.toInt() ?? 0;
          (byDay[dow] ??= []).add(TimetablePeriod(
            subject: s['subject'] as String? ?? 'Subject',
            teacher: s['teacher'] as String?,
            room: s['room'] as String?,
            start: hhmm(s['start_time'] as String?),
            end: hhmm(s['end_time'] as String?),
          ));
        }
        final days = <TimetableDay>[];
        for (var i = 0; i < 7; i++) {
          // A growable copy: sorting a const empty list throws on free days.
          final periods = [...?byDay[i]];
          if (periods.isEmpty && i > 4) continue; // hide empty weekends
          periods.sort((a, b) => a.start.compareTo(b.start));
          days.add(TimetableDay(
            weekday: i,
            label: labels[i],
            isToday: i == today,
            periods: periods,
          ));
        }
        return days;
      },
    );
  }

  /// Live notifications from server-authorized broadcasts for this student.
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
          timeAgo: _relative((m['sent_at'] ?? m['scheduled_at']) as String?),
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
    String? attachmentUrl,
  }) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: StudentEndpoints.submitAssignment(_sid, id),
      body: {
        'content': ?notes,
        'attachment_url': ?attachmentUrl,
      },
    );
  }

  /// Uploads a file to the school's storage bucket and returns its public URL,
  /// which is then stored as the submission's `attachment_url`. The backend
  /// picks the storage provider (local disk in dev, cloud in prod) — this call
  /// is provider-agnostic.
  Future<ApiResponse<String>> uploadFile({
    required List<int> bytes,
    required String filename,
    String contentType = 'application/pdf',
  }) {
    return _api.request<String>(
      method: HttpMethod.multipart,
      path: StudentEndpoints.uploads(_sid),
      files: [
        MultipartUpload(
          field: 'file',
          filename: filename,
          bytes: bytes,
          contentType: contentType,
        ),
      ],
      parser: (json) => (json as Map<String, dynamic>)['url'] as String? ?? '',
    );
  }

  // ──────────────────────────────── quizzes ───────────────────────────────

  /// Quizzes assigned to the student (section-wide or targeted at them), merged
  /// with their own attempt (score/state). Scoping is enforced server-side.
  Future<ApiResponse<List<StudentQuiz>>> fetchQuizzes() async {
    final quizzesRes = await _api.request<List<StudentQuiz>>(
      method: HttpMethod.get,
      path: StudentEndpoints.quizzesAssigned(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(StudentQuiz.fromJson)
          .toList(),
    );
    if (!quizzesRes.success || quizzesRes.data == null) return quizzesRes;

    final attemptsRes = await _api.request<List<QuizAttempt>>(
      method: HttpMethod.get,
      path: StudentEndpoints.studentQuizAttempts(_sid, _uid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(QuizAttempt.fromJson)
          .toList(),
    );
    final byQuiz = <String, QuizAttempt>{
      for (final a in attemptsRes.data ?? const <QuizAttempt>[]) a.quizId: a,
    };
    return ApiResponse.ok(
      quizzesRes.data!.map((q) => q.withAttempt(byQuiz[q.id])).toList(),
    );
  }

  /// A quiz's questions for the student to attempt.
  Future<ApiResponse<StudentQuizDetail>> fetchQuizDetail(String quizId) {
    return _api.request<StudentQuizDetail>(
      method: HttpMethod.get,
      path: StudentEndpoints.quizDetail(_sid, quizId),
      parser: (json) =>
          StudentQuizDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Submits answers (question id → chosen option) and returns the graded result.
  Future<ApiResponse<QuizResult>> submitQuiz(
      String quizId, Map<String, String> answers) {
    return _api.request<QuizResult>(
      method: HttpMethod.post,
      path: StudentEndpoints.quizSubmit(_sid, quizId),
      body: {
        'answers': [
          for (final e in answers.entries)
            {'question_id': e.key, 'response': e.value},
        ],
      },
      parser: (json) => QuizResult.fromJson(json as Map<String, dynamic>),
    );
  }

  // ─────────────────────────── Courses ───────────────────────────

  /// Available courses for the school, from `/schools/{id}/courses`.
  Future<ApiResponse<List<Course>>> fetchCourses() {
    return _api.request<List<Course>>(
      method: HttpMethod.get,
      path: StudentEndpoints.courses(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(Course.fromJson)
          .toList(),
    );
  }

  /// Books within a course (each with its chapter count).
  Future<ApiResponse<List<CourseBook>>> fetchCourseBooks(String courseId) {
    return _api.request<List<CourseBook>>(
      method: HttpMethod.get,
      path: StudentEndpoints.courseBooks(_sid, courseId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(CourseBook.fromJson)
          .toList(),
    );
  }

  /// A book's chapter list (table of contents — titles only).
  Future<ApiResponse<List<ChapterBrief>>> fetchBookChapters(String bookId) {
    return _api.request<List<ChapterBrief>>(
      method: HttpMethod.get,
      path: StudentEndpoints.bookChapters(_sid, bookId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ChapterBrief.fromJson)
          .toList(),
    );
  }

  /// One chapter with its full text body.
  Future<ApiResponse<Chapter>> fetchChapter(String chapterId) {
    return _api.request<Chapter>(
      method: HttpMethod.get,
      path: StudentEndpoints.chapter(_sid, chapterId),
      parser: (json) => Chapter.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Notes within a course (titles only).
  Future<ApiResponse<List<NoteBrief>>> fetchCourseNotes(String courseId) {
    return _api.request<List<NoteBrief>>(
      method: HttpMethod.get,
      path: StudentEndpoints.courseNotes(_sid, courseId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(NoteBrief.fromJson)
          .toList(),
    );
  }

  /// One note with its full text body.
  Future<ApiResponse<Note>> fetchNote(String noteId) {
    return _api.request<Note>(
      method: HttpMethod.get,
      path: StudentEndpoints.note(_sid, noteId),
      parser: (json) => Note.fromJson(json as Map<String, dynamic>),
    );
  }

  /// The caller's saved reading position for a book/note (page 0 if none).
  Future<ApiResponse<ReadingProgress>> fetchReadingProgress({
    required String resourceType,
    required String resourceId,
  }) {
    return _api.request<ReadingProgress>(
      method: HttpMethod.get,
      path: StudentEndpoints.readingProgressLookup(_sid),
      query: {'resource_type': resourceType, 'resource_id': resourceId},
      parser: (json) => ReadingProgress.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Persists the caller's reading position for a book/note.
  Future<ApiResponse<ReadingProgress>> saveReadingProgress({
    required String resourceType,
    required String resourceId,
    String? chapterId,
    required int page,
  }) {
    return _api.request<ReadingProgress>(
      method: HttpMethod.put,
      path: StudentEndpoints.readingProgress(_sid),
      body: {
        'resource_type': resourceType,
        'resource_id': resourceId,
        'chapter_id': ?chapterId,
        'page': page,
      },
      parser: (json) => ReadingProgress.fromJson(json as Map<String, dynamic>),
    );
  }

  // ─────────────────────────── Leave ───────────────────────────

  /// The student's own leave applications, newest state first.
  Future<ApiResponse<List<LeaveRequest>>> fetchMyLeave() {
    return _api.request<List<LeaveRequest>>(
      method: HttpMethod.get,
      path: StudentEndpoints.leaveMine(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(LeaveRequest.fromJson)
          .toList(),
    );
  }

  /// Submits a new leave application; it is routed to reviewers server-side.
  Future<ApiResponse<LeaveRequest>> submitLeave({
    String? leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) {
    return _api.request<LeaveRequest>(
      method: HttpMethod.post,
      path: StudentEndpoints.leaveRequests(_sid),
      body: {
        'leave_type': ?leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': ?reason,
      },
      parser: (json) => LeaveRequest.fromJson(json as Map<String, dynamic>),
    );
  }

  // ------------------------------ transport ---------------------------- #

  Future<ApiResponse<MyTransportRequest>> createTransportRequest({
    required String pickupAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return _api.request<MyTransportRequest>(
      method: HttpMethod.post,
      path: StudentEndpoints.transportRequests(_sid),
      body: {
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
      path: StudentEndpoints.transportRequestsMine(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(MyTransportRequest.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<ActiveTrip>>> fetchActiveTrips() {
    return _api.request<List<ActiveTrip>>(
      method: HttpMethod.get,
      path: StudentEndpoints.transportTripsActive(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(ActiveTrip.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<TripLocation>> fetchTripLocation(String tripId) {
    return _api.request<TripLocation>(
      method: HttpMethod.get,
      path: StudentEndpoints.transportTripLocation(_sid, tripId),
      parser: (json) => TripLocation.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TripEta>> fetchTripEta(String tripId) {
    return _api.request<TripEta>(
      method: HttpMethod.get,
      path: StudentEndpoints.transportTripEta(_sid, tripId),
      parser: (json) => TripEta.fromJson(json as Map<String, dynamic>),
    );
  }

  // ─────────────────────────── School info ───────────────────────────

  /// The public school profile (about, achievements, uniform, contacts).
  Future<ApiResponse<SchoolInfo>> fetchSchoolInfo() {
    return _api.request<SchoolInfo>(
      method: HttpMethod.get,
      path: StudentEndpoints.schoolInfo(_sid),
      parser: (json) => SchoolInfo.fromJson(json as Map<String, dynamic>),
    );
  }
}
