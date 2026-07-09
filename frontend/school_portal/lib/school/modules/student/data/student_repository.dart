import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/assignments/models/assignments_repository.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/exams/models/exam.dart';
import '../features/exams/models/exams_repository.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/notifications/models/notifications_repository.dart';
import '../features/quiz/models/quiz_models.dart';
import '../features/results/models/exam_result.dart';
import '../features/results/models/report_card.dart';
import '../features/timetable/models/timetable_data.dart';
import 'student_api_service.dart';

/// Single data gateway for the Student module. Every Student controller depends
/// on this class (never on [StudentApiService] or [ApiService] directly).
///
/// Flip [_useMock] to `false` to route through the live [StudentApiService];
/// while `true` the methods return the bundled per-feature mock fixtures.
class StudentRepository {
  final StudentApiService _api;

  final _attendanceMock = AttendanceRepository();
  final _assignmentsMock = AssignmentsRepository();
  final _examsMock = ExamsRepository();
  final _notificationsMock = NotificationsRepository();

  StudentRepository({StudentApiService? api})
      : _api = api ?? StudentApiService();

  // Only single-assignment detail lacks a backend mapping (there's no
  // GET /assignments/{id}) → stays on mock. Everything else is wired live.
  static const bool _useMock = true;

  // Per-feature live flags: real `/schools/{id}/...` calls (with documented
  // field losses — see StudentApiService). Flip to false to revert to mock.
  static const bool _liveAssignments = true;
  static const bool _liveExams = true;
  static const bool _liveSubmit = true;
  static const bool _liveAttendance = true;
  static const bool _liveNotifications = true;

  Future<ApiResponse<AttendanceData>> loadAttendance() =>
      _liveAttendance ? _api.fetchAttendance() : _attendanceMock.load();

  Future<ApiResponse<AssignmentsData>> loadAssignments() =>
      _liveAssignments ? _api.fetchAssignments() : _assignmentsMock.load();

  Future<ApiResponse<StudentAssignment>> loadAssignment(String id) =>
      _useMock ? _assignmentsMock.fetchOne(id) : _api.fetchAssignment(id);

  Future<ApiResponse<ExamsData>> loadExams() =>
      _liveExams ? _api.fetchExams() : _examsMock.load();

  /// Scheduled papers (subjects) for one exam — always live (no mock fixture).
  Future<ApiResponse<List<ExamPaper>>> loadExamPapers(String examId) =>
      _api.fetchExamPapers(examId);

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _liveNotifications ? _api.fetchNotifications() : _notificationsMock.load();

  Future<ApiResponse<void>> submitAssignment(String id,
      {String? notes, String? attachmentUrl}) async {
    if (_liveSubmit) {
      return _api.submitAssignment(id, notes: notes, attachmentUrl: attachmentUrl);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return ApiResponse.ok(null);
  }

  /// Uploads a submission attachment and returns its stored URL.
  Future<ApiResponse<String>> uploadFile({
    required List<int> bytes,
    required String filename,
    String contentType = 'application/pdf',
  }) =>
      _api.uploadFile(bytes: bytes, filename: filename, contentType: contentType);

  // ── Quizzes (always live) ──
  Future<ApiResponse<List<StudentQuiz>>> loadQuizzes() => _api.fetchQuizzes();

  Future<ApiResponse<List<ExamResultItem>>> loadExamResults() =>
      _api.fetchExamResults();

  Future<ApiResponse<ReportCard>> loadReportCard(String examId) =>
      _api.fetchReportCard(examId);

  Future<ApiResponse<List<TimetableDay>>> loadTimetable() =>
      _api.fetchTimetable();

  Future<ApiResponse<StudentQuizDetail>> loadQuizDetail(String quizId) =>
      _api.fetchQuizDetail(quizId);

  Future<ApiResponse<QuizResult>> submitQuiz(
          String quizId, Map<String, String> answers) =>
      _api.submitQuiz(quizId, answers);
}
