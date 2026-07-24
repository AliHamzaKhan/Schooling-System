import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/attendance/models/attendance_data.dart';
import '../features/exams/models/exam.dart';
import '../features/notifications/models/notification_item.dart';
import '../features/quiz/models/quiz_models.dart';
import '../features/results/models/exam_result.dart';
import '../features/results/models/report_card.dart';
import '../features/timetable/models/timetable_data.dart';
import 'student_api_service.dart';

/// Single data gateway for the Student module. Every Student controller depends
/// on this class (never on [StudentApiService] or [ApiService] directly).
///
/// Every method reads live backend data through [StudentApiService].
class StudentRepository {
  final StudentApiService _api;

  StudentRepository({StudentApiService? api})
      : _api = api ?? StudentApiService();

  Future<ApiResponse<AttendanceData>> loadAttendance() =>
      _api.fetchAttendance();

  Future<ApiResponse<AssignmentsData>> loadAssignments() =>
      _api.fetchAssignments();

  Future<ApiResponse<StudentAssignment>> loadAssignment(String id) =>
      _api.fetchAssignment(id);

  Future<ApiResponse<ExamsData>> loadExams() => _api.fetchExams();

  /// Scheduled papers (subjects) for one exam.
  Future<ApiResponse<List<ExamPaper>>> loadExamPapers(String examId) =>
      _api.fetchExamPapers(examId);

  Future<ApiResponse<List<NotificationItem>>> loadNotifications() =>
      _api.fetchNotifications();

  Future<ApiResponse<void>> submitAssignment(String id,
          {String? notes, String? attachmentUrl}) =>
      _api.submitAssignment(id, notes: notes, attachmentUrl: attachmentUrl);

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
