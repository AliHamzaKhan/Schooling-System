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
import 'teacher_api_service.dart';

/// One subject paper to attach to a new exam.
class ExamPaperDraft {
  final String subjectId;
  final double maxMarks;
  final double passMarks;
  const ExamPaperDraft({
    required this.subjectId,
    required this.maxMarks,
    required this.passMarks,
  });
}

/// Single data gateway for the Teacher module. Every Teacher controller depends
/// on this class (never on [TeacherApiService] or [ApiService] directly).
///
/// Every method reads/writes live backend data through [TeacherApiService].
class TeacherRepository {
  final TeacherApiService _api;

  TeacherRepository({TeacherApiService? api})
      : _api = api ?? TeacherApiService();

  Future<ApiResponse<DashboardData>> loadDashboard() =>
      _api.fetchDashboard();

  Future<ApiResponse<List<TeachingClass>>> loadClasses() =>
      _api.fetchClasses();

  /// Publishes an announcement.
  Future<ApiResponse<dynamic>> createBroadcast({
    required String channel,
    required String audienceType,
    String? audienceRef,
    String? title,
    required String body,
  }) =>
      _api.createBroadcast(
        channel: channel,
        audienceType: audienceType,
        audienceRef: audienceRef,
        title: title,
        body: body,
      );

  /// Section roster ranked by attendance + marks (live only — no fixture).
  Future<ApiResponse<SectionPerformance>> loadSectionPerformance(
          String sectionId) =>
      _api.fetchSectionPerformance(sectionId);

  Future<ApiResponse<List<TeacherSlot>>> loadMyTimetable({DateTime? onDate}) =>
      _api.fetchMyTimetable(onDate: onDate);

  /// Distinct subject names for the school (live only — no mock fixture).
  Future<ApiResponse<List<String>>> loadSubjects() => _api.fetchSubjects();

  Future<ApiResponse<List<AttendanceClass>>> loadAttendanceClasses() =>
      _api.fetchAttendanceClasses();

  Future<ApiResponse<List<AttendanceStudent>>> loadAttendanceStudents(
          String classId) =>
      _api.fetchAttendanceStudents(classId);

  Future<ApiResponse<void>> saveAttendanceMarks(
          String sectionId, Map<String, String> marks) =>
      _api.saveAttendanceMarks(sectionId, marks);

  Future<ApiResponse<AssignmentsData>> loadAssignments({String? classFilter}) =>
      _api.fetchAssignments(classFilter: classFilter);

  Future<ApiResponse<List<MessageThread>>> loadMessages({
    String query = '',
    ThreadParty? party,
  }) =>
      _api.fetchMessages(query: query, party: party?.name);

  /// Papers available to grade (live only — no fixture).
  Future<ApiResponse<List<GradablePaper>>> loadGradablePapers() =>
      _api.fetchGradablePapers();

  Future<ApiResponse<Gradebook>> loadGradebook(String paperId) =>
      _api.fetchGradebook(paperId);

  Future<ApiResponse<void>> saveMarks(String paperId, Map<String, double> marks) =>
      _api.saveMarks(paperId, marks);

  Future<ApiResponse<StudentDetail>> loadStudentPerformance(String studentId) =>
      _api.fetchStudentPerformance(studentId);

  Future<ApiResponse<void>> createHomework({
    required String sectionId,
    required String subjectId,
    required String title,
    String? description,
    required String dueDate,
    double? maxMarks,
  }) =>
      _api.createHomework(
        sectionId: sectionId,
        subjectId: subjectId,
        title: title,
        description: description,
        dueDate: dueDate,
        maxMarks: maxMarks,
      );

  /// Creates an exam and its subject papers in one call: POST the exam shell,
  /// then POST each paper. Returns the first failure encountered, so a partial
  /// create surfaces an error rather than a false success.
  Future<ApiResponse<void>> createExam({
    required String classId,
    required String name,
    String? startDate,
    String? endDate,
    required List<ExamPaperDraft> papers,
  }) async {
    final examRes = await _api.createExam(
      classId: classId,
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
    if (!examRes.success || examRes.data == null) {
      return ApiResponse.fail(examRes.error ?? 'Could not create the exam.');
    }
    final examId = examRes.data!;
    for (final p in papers) {
      final paperRes = await _api.addExamPaper(
        examId: examId,
        subjectId: p.subjectId,
        maxMarks: p.maxMarks,
        passMarks: p.passMarks,
      );
      if (!paperRes.success) {
        return ApiResponse.fail(
            paperRes.error ?? 'Exam created, but a paper failed to save.');
      }
    }
    return ApiResponse.ok(null);
  }

  // ── Quizzes (always live) ──
  Future<ApiResponse<List<TeacherQuiz>>> loadQuizzes() => _api.fetchQuizzes();

  Future<ApiResponse<String>> createQuiz({
    required String sectionId,
    required String subjectId,
    required String title,
    String? description,
    int? timeLimitMinutes,
    List<String>? assigneeIds,
  }) =>
      _api.createQuiz(
        sectionId: sectionId,
        subjectId: subjectId,
        title: title,
        description: description,
        timeLimitMinutes: timeLimitMinutes,
        assigneeIds: assigneeIds,
      );

  Future<ApiResponse<List<IdLabel>>> loadSectionStudents(String sectionId) =>
      _api.fetchSectionStudents(sectionId);

  Future<ApiResponse<QuizPerformance>> loadQuizPerformance(String quizId) =>
      _api.fetchQuizPerformance(quizId);

  Future<ApiResponse<List<DraftQuestion>>> generateQuizQuestions({
    required List<int> bytes,
    required String filename,
  }) =>
      _api.generateQuizQuestions(bytes: bytes, filename: filename);

  Future<ApiResponse<dynamic>> addQuizQuestion(
          String quizId, Map<String, dynamic> question) =>
      _api.addQuestion(quizId, question);

  Future<ApiResponse<dynamic>> publishQuiz(String quizId) =>
      _api.publishQuiz(quizId);

  Future<ApiResponse<List<IdLabel>>> loadSectionOptions() =>
      _api.fetchSectionOptions();

  Future<ApiResponse<List<IdLabel>>> loadSubjectOptions() =>
      _api.fetchSubjectOptions();

  // ── Homework grading ──
  Future<ApiResponse<List<SubmissionRow>>> loadSubmissions(String assignmentId) =>
      _api.fetchSubmissions(assignmentId);

  Future<ApiResponse<dynamic>> gradeSubmission({
    required String submissionId,
    required double marks,
    String? feedback,
  }) =>
      _api.gradeSubmission(
          submissionId: submissionId, marks: marks, feedback: feedback);

  // ── Leave review ──
  Future<ApiResponse<List<LeaveReviewItem>>> loadLeaveReview() =>
      _api.fetchLeaveReview();

  Future<ApiResponse<dynamic>> reviewLeave({
    required String leaveId,
    required bool approve,
    String? note,
  }) =>
      _api.reviewLeave(leaveId: leaveId, approve: approve, note: note);
}
