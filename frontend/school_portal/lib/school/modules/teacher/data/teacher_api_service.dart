import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../widgets/leave_review.dart';
import '../features/grading/models/submission_row.dart';
import '../features/performance/models/section_performance.dart';
import '../features/assignments/models/assignment.dart';
import '../features/attendance/models/attendance_models.dart';
import '../features/calendar/models/timetable_slot.dart';
import '../features/classes/models/teaching_class.dart';
import '../features/communication/models/message_thread.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/gradebook/models/gradebook_data.dart';
import '../features/performance/models/performance_data.dart';
import '../features/quiz/models/quiz_models.dart';
import 'teacher_endpoints.dart';

/// Network layer for the Teacher module. Owns every Teacher HTTP call, building
/// requests through the shared [ApiService] (auth headers, base URL, envelope
/// unwrapping, error handling) against [TeacherEndpoints], and parsing payloads
/// into typed models. Reached only via `TeacherRepository`.
class TeacherApiService {
  final ApiService _api;
  TeacherApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  /// The signed-in teacher's school id — every live endpoint is scoped to it.
  String get _sid => Get.find<AuthService>().schoolId ?? '';

  /// The teacher home screen — schedule, to-dos, and recent activity, all
  /// database-derived. No fixture behind it.
  Future<ApiResponse<DashboardData>> fetchDashboard() {
    return _api.request<DashboardData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.myDashboard(_sid),
      parser: (json) => DashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Live classes from `/schools/{id}/academic/classes` (`ClassOut`: name,
  /// level). The backend exposes no per-class student counts or descriptions,
  /// so those default to 0 / empty.
  Future<ApiResponse<List<TeachingClass>>> fetchClasses() {
    return _api.request<List<TeachingClass>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.academicClasses(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((c) {
            final level = (c['level'] as num?)?.toInt();
            return TeachingClass(
              id: '${c['id']}',
              subject: c['name'] as String? ?? '',
              grade: level == null ? '' : 'Grade $level',
              description: '',
              students: 0,
              accent: AppColors.primary,
            );
          })
          .toList(),
    );
  }

  /// Live subject names from `/schools/{id}/academic/subjects` (`SubjectOut`:
  /// id, name). Used to populate the Create Exam subject picker with real
  /// subjects rather than class names.
  Future<ApiResponse<List<String>>> fetchSubjects() {
    return _api.request<List<String>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.academicSubjects(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((s) => s['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
    );
  }

  /// Every active student in a section with attendance + marks, already
  /// ranked best-first by the backend.
  Future<ApiResponse<SectionPerformance>> fetchSectionPerformance(
      String sectionId) {
    return _api.request<SectionPerformance>(
      method: HttpMethod.get,
      path: TeacherEndpoints.sectionPerformance(_sid, sectionId),
      parser: (json) =>
          SectionPerformance.fromJson(json as Map<String, dynamic>),
    );
  }

  /// The teacher's weekly timetable. Pass [onDate] to have each period report
  /// whether its attendance is already marked that day.
  Future<ApiResponse<List<TeacherSlot>>> fetchMyTimetable({DateTime? onDate}) {
    return _api.request<List<TeacherSlot>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.myTimetable(_sid),
      query: onDate == null
          ? null
          : {
              'on_date':
                  '${onDate.year.toString().padLeft(4, '0')}-${onDate.month.toString().padLeft(2, '0')}-${onDate.day.toString().padLeft(2, '0')}',
            },
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(TeacherSlot.fromJson)
          .toList(),
    );
  }

  /// Sections the teacher takes, folded up from their own timetable.
  ///
  /// There is no aggregate "/teacher/attendance/classes" endpoint — the real
  /// source is the timetable, grouped by section, which also gives the true
  /// head-count per section.
  Future<ApiResponse<List<AttendanceClass>>> fetchAttendanceClasses() async {
    final res = await fetchMyTimetable();
    if (!res.success) {
      return ApiResponse.fail(res.error ?? 'Could not load your classes.');
    }
    final bySection = <String, List<TeacherSlot>>{};
    for (final slot in res.data ?? const <TeacherSlot>[]) {
      bySection.putIfAbsent(slot.sectionId, () => []).add(slot);
    }
    final classes = bySection.values.map((group) {
      final first = group.first;
      final subjects = group.map((s) => s.subject).toSet().toList()..sort();
      return AttendanceClass(
        id: first.sectionId,
        subject: subjects.join(', '),
        grade: '${first.className} ${first.sectionName}',
        students: first.studentCount,
        icon: AppIcons.classOutlined,
        color: AppColors.primary,
      );
    }).toList()
      ..sort((a, b) => a.grade.compareTo(b.grade));
    return ApiResponse.ok(classes);
  }

  /// The section's active roster, names included.
  Future<ApiResponse<List<AttendanceStudent>>> fetchAttendanceStudents(
      String sectionId) {
    return _api.request<List<AttendanceStudent>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.sectionStudents(_sid, sectionId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((e) => AttendanceStudent(
                id: '${e['student_id']}',
                name: e['student_name'] as String? ?? 'Student',
                accent: AppColors.primary,
              ))
          .toList(),
    );
  }

  /// Saves the daily register for a section.
  ///
  /// Unmarked students are skipped rather than defaulted, so a half-finished
  /// register never records an absence nobody entered.
  Future<ApiResponse<void>> saveAttendanceMarks(
      String sectionId, Map<String, String> marks) {
    final entries = [
      for (final e in marks.entries)
        if (e.value != 'unmarked')
          {'student_id': e.key, 'status': e.value},
    ];
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.attendance(_sid),
      body: {
        'section_id': sectionId,
        'attendance_date': date,
        'entries': entries,
      },
    );
  }

  /// Live assignments from `/schools/{id}/homework/assignments` (list of
  /// `AssignmentOut`). The backend has no per-assignment class name,
  /// submission counts, or KPI stats, so [Assignment.className] is blank,
  /// turned-in/total are 0, and the header stats are derived from the list
  /// (active = due in the future). [classFilter] is ignored (no class name to
  /// match server- or client-side).
  Future<ApiResponse<AssignmentsData>> fetchAssignments({String? classFilter}) {
    return _api.request<AssignmentsData>(
      method: HttpMethod.get,
      path: TeacherEndpoints.homeworkAssignments(_sid),
      parser: (json) {
        final now = DateTime.now();
        final items = (json as List).cast<Map<String, dynamic>>().map((a) {
          final due = DateTime.tryParse(a['due_date'] as String? ?? '');
          final isClosed = due != null && due.isBefore(now);
          return Assignment(
            id: '${a['id']}',
            title: a['title'] as String? ?? '',
            className: '',
            dueLabel: a['due_date'] as String? ?? '',
            status:
                isClosed ? AssignmentStatus.closed : AssignmentStatus.active,
            turnedIn: (a['submission_count'] as num?)?.toInt() ?? 0,
            total: 0,
            icon: AppIcons.assignmentOutlined,
            iconAccent: AppColors.primary,
            maxMarks: (a['max_marks'] as num?)?.toDouble(),
          );
        }).toList();
        final active =
            items.where((a) => a.status == AssignmentStatus.active).length;
        return AssignmentsData(
          stats: AssignmentStats(
            toGrade: 0,
            toGradeDelta: 0,
            activeCount: active,
            activeAcrossClasses: 0,
            averageTurnInRate: 0,
            averageTurnInDelta: 0,
          ),
          assignments: items,
        );
      },
    );
  }

  /// Publishes an announcement via `POST /communication/broadcasts`.
  Future<ApiResponse<dynamic>> createBroadcast({
    required String channel,
    required String audienceType,
    String? audienceRef,
    String? title,
    required String body,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: TeacherEndpoints.broadcasts(_sid),
      body: {
        'channel': channel,
        'audience_type': audienceType,
        'audience_ref': ?audienceRef,
        'title': ?title,
        'body': body,
      },
      parser: (json) => json,
    );
  }

  /// Live message threads from school broadcasts
  /// (`/schools/{id}/communication/broadcasts`, `MessageOut` list). The backend
  /// has no per-thread sender/party or read state, so every item maps to
  /// [ThreadParty.parent] with the broadcast title as the sender; `time` shows
  /// the sent/scheduled timestamp. [query]/[party] filter client-side.
  Future<ApiResponse<List<MessageThread>>> fetchMessages({
    String query = '',
    String? party,
  }) {
    final q = query.trim().toLowerCase();
    return _api.request<List<MessageThread>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.broadcasts(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((m) {
            final body = m['body'] as String? ?? '';
            return MessageThread(
              id: '${m['id']}',
              senderName: m['title'] as String? ?? 'Broadcast',
              preview: body,
              time: (m['sent_at'] ?? m['scheduled_at']) as String? ?? '',
              party: ThreadParty.parent,
            );
          })
          .where((t) =>
              q.isEmpty ||
              t.senderName.toLowerCase().contains(q) ||
              t.preview.toLowerCase().contains(q))
          .toList(),
    );
  }

  /// Papers the teacher can grade, across every exam in the school.
  ///
  /// Exams don't record which teacher owns a paper, so this lists all of them
  /// and lets the teacher choose — rather than inventing an ownership rule the
  /// data can't support.
  Future<ApiResponse<List<GradablePaper>>> fetchGradablePapers() async {
    final exams = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.schoolExams(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!exams.success) {
      return ApiResponse.fail(exams.error ?? 'Could not load exams.');
    }

    final subjects = await fetchSubjectOptions();
    final subjectNames = {
      for (final s in subjects.data ?? const <IdLabel>[]) s.id: s.label,
    };

    final papers = <GradablePaper>[];
    for (final exam in exams.data ?? const <Map<String, dynamic>>[]) {
      final examId = '${exam['id']}';
      final res = await _api.request<List<Map<String, dynamic>>>(
        method: HttpMethod.get,
        path: TeacherEndpoints.examPapers(_sid, examId),
        parser: (json) => (json as List).cast<Map<String, dynamic>>(),
      );
      for (final paper in res.data ?? const <Map<String, dynamic>>[]) {
        papers.add(GradablePaper(
          paperId: '${paper['id']}',
          examName: exam['name'] as String? ?? 'Exam',
          subjectName: subjectNames['${paper['subject_id']}'] ?? 'Subject',
          maxMarks: (paper['max_marks'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return ApiResponse.ok(papers);
  }

  /// The full marks sheet for one paper.
  Future<ApiResponse<Gradebook>> fetchGradebook(String paperId) {
    return _api.request<Gradebook>(
      method: HttpMethod.get,
      path: TeacherEndpoints.paperGradebook(_sid, paperId),
      parser: (json) => Gradebook.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Persists entered marks. Students left blank are omitted, so a partly
  /// filled sheet never records a zero nobody typed.
  Future<ApiResponse<void>> saveMarks(
      String paperId, Map<String, double> marks) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.paperMarks(_sid, paperId),
      body: {
        'entries': [
          for (final e in marks.entries)
            {'student_id': e.key, 'marks_obtained': e.value},
        ],
      },
    );
  }

  Future<ApiResponse<StudentDetail>> fetchStudentPerformance(String studentId) {
    return _api.request<StudentDetail>(
      method: HttpMethod.get,
      path: TeacherEndpoints.studentPerformance(_sid, studentId),
      parser: (json) => StudentDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Posts a homework assignment to `/schools/{id}/homework/assignments`.
  Future<ApiResponse<void>> createHomework({
    required String sectionId,
    required String subjectId,
    required String title,
    String? description,
    required String dueDate,
    double? maxMarks,
  }) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.homeworkAssignments(_sid),
      body: {
        'section_id': sectionId,
        'subject_id': subjectId,
        'title': title,
        'description': ?((description != null && description.isEmpty) ? null : description),
        'due_date': dueDate,
        'max_marks': ?maxMarks,
      },
    );
  }

  /// Creates an exam shell and returns its id, so papers can be attached.
  Future<ApiResponse<String>> createExam({
    required String classId,
    required String name,
    String? startDate,
    String? endDate,
  }) {
    return _api.request<String>(
      method: HttpMethod.post,
      path: TeacherEndpoints.schoolExams(_sid),
      body: {
        'class_id': classId,
        'name': name,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
      parser: (json) => '${(json as Map<String, dynamic>)['id']}',
    );
  }

  /// Adds one subject paper (with its marks) to an exam.
  Future<ApiResponse<void>> addExamPaper({
    required String examId,
    required String subjectId,
    required double maxMarks,
    required double passMarks,
    String? examDate,
  }) {
    return _api.request<void>(
      method: HttpMethod.post,
      path: TeacherEndpoints.examPapers(_sid, examId),
      body: {
        'subject_id': subjectId,
        'max_marks': maxMarks,
        'pass_marks': passMarks,
        'exam_date': ?examDate,
      },
    );
  }

  // ──────────────────────────────── quizzes ───────────────────────────────

  /// Quizzes created for this school (`QuizOut` list).
  Future<ApiResponse<List<TeacherQuiz>>> fetchQuizzes() {
    return _api.request<List<TeacherQuiz>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.quizzes(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(TeacherQuiz.fromJson)
          .toList(),
    );
  }

  /// Creates a quiz (draft) and returns its id. When [assigneeIds] is non-empty
  /// the quiz targets only those students; otherwise it is section-wide.
  Future<ApiResponse<String>> createQuiz({
    required String sectionId,
    required String subjectId,
    required String title,
    String? description,
    int? timeLimitMinutes,
    List<String>? assigneeIds,
  }) {
    return _api.request<String>(
      method: HttpMethod.post,
      path: TeacherEndpoints.quizzes(_sid),
      body: {
        'section_id': sectionId,
        'subject_id': subjectId,
        'title': title,
        'description': ?description,
        'time_limit_minutes': ?timeLimitMinutes,
        if (assigneeIds != null && assigneeIds.isNotEmpty)
          'assignee_ids': assigneeIds,
      },
      parser: (json) => '${(json as Map<String, dynamic>)['id']}',
    );
  }

  /// Enrolled students of a section (for the assignee picker).
  Future<ApiResponse<List<IdLabel>>> fetchSectionStudents(String sectionId) {
    return _api.request<List<IdLabel>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.quizSectionStudents(_sid, sectionId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((s) => IdLabel('${s['student_id']}', s['name'] as String? ?? ''))
          .toList(),
    );
  }

  /// Per-student scores for a quiz.
  Future<ApiResponse<QuizPerformance>> fetchQuizPerformance(String quizId) {
    return _api.request<QuizPerformance>(
      method: HttpMethod.get,
      path: TeacherEndpoints.quizPerformance(_sid, quizId),
      parser: (json) => QuizPerformance.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Uploads a PDF and returns AI-generated draft MCQs to pre-fill the form.
  Future<ApiResponse<List<DraftQuestion>>> generateQuizQuestions({
    required List<int> bytes,
    required String filename,
  }) {
    return _api.request<List<DraftQuestion>>(
      method: HttpMethod.multipart,
      path: TeacherEndpoints.quizGenerateQuestions(_sid),
      files: [
        MultipartUpload(
          field: 'file',
          filename: filename,
          bytes: bytes,
          contentType: 'application/pdf',
        ),
      ],
      parser: (json) => (json as List).cast<Map<String, dynamic>>().map((q) {
        final options =
            ((q['options'] as List?) ?? const []).map((e) => '$e').toList();
        final correct = q['correct_answer'] as String? ?? '';
        final idx = options.indexOf(correct);
        return DraftQuestion(
          prompt: q['prompt'] as String? ?? '',
          options: options,
          correctIndex: idx < 0 ? 0 : idx,
          marks: (q['marks'] as num?)?.toDouble() ?? 1,
        );
      }).toList(),
    );
  }

  /// Adds one question to a quiz.
  Future<ApiResponse<dynamic>> addQuestion(
      String quizId, Map<String, dynamic> question) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: TeacherEndpoints.quizQuestions(_sid, quizId),
      body: question,
      parser: (json) => json,
    );
  }

  /// Publishes a quiz (opens it for student attempts).
  Future<ApiResponse<dynamic>> publishQuiz(String quizId) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: TeacherEndpoints.quizPublish(_sid, quizId),
      parser: (json) => json,
    );
  }

  /// Flattened "Grade · Section" options built from classes + their sections.
  Future<ApiResponse<List<IdLabel>>> fetchSectionOptions() async {
    final classesRes = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.academicClasses(_sid),
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!classesRes.success || classesRes.data == null) {
      return ApiResponse.fail(classesRes.error ?? 'Could not load classes');
    }
    final out = <IdLabel>[];
    for (final c in classesRes.data!) {
      final classId = '${c['id']}';
      final className = c['name'] as String? ?? '';
      final secRes = await _api.request<List<Map<String, dynamic>>>(
        method: HttpMethod.get,
        path: TeacherEndpoints.academicClassSections(_sid, classId),
        parser: (json) => (json as List).cast<Map<String, dynamic>>(),
      );
      for (final s in secRes.data ?? const <Map<String, dynamic>>[]) {
        out.add(IdLabel('${s['id']}', '$className · ${s['name'] ?? ''}'));
      }
    }
    return ApiResponse.ok(out);
  }

  /// Subject id/name options from the subject catalog.
  Future<ApiResponse<List<IdLabel>>> fetchSubjectOptions() {
    return _api.request<List<IdLabel>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.academicSubjects(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map((s) => IdLabel('${s['id']}', s['name'] as String? ?? ''))
          .toList(),
    );
  }

  // ─────────────────────── Homework grading ───────────────────────

  Future<ApiResponse<List<SubmissionRow>>> fetchSubmissions(String assignmentId) {
    return _api.request<List<SubmissionRow>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.assignmentSubmissions(_sid, assignmentId),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(SubmissionRow.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<dynamic>> gradeSubmission({
    required String submissionId,
    required double marks,
    String? feedback,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.patch,
      path: TeacherEndpoints.gradeSubmission(_sid, submissionId),
      body: {'marks_obtained': marks, 'feedback': ?feedback},
      parser: (json) => json,
    );
  }

  // ─────────────────────── Leave review ───────────────────────

  Future<ApiResponse<List<LeaveReviewItem>>> fetchLeaveReview() {
    return _api.request<List<LeaveReviewItem>>(
      method: HttpMethod.get,
      path: TeacherEndpoints.leaveForReview(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(LeaveReviewItem.fromJson)
          .toList(),
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
          ? TeacherEndpoints.leaveApprove(_sid, leaveId)
          : TeacherEndpoints.leaveReject(_sid, leaveId),
      body: {'note': ?note},
      parser: (json) => json,
    );
  }
}
