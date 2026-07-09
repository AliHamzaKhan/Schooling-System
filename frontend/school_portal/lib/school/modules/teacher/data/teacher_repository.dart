import 'package:shared/shared.dart';

import '../features/assignments/models/assignment.dart';
import '../features/assignments/models/assignments_repository.dart';
import '../features/attendance/models/attendance_models.dart';
import '../features/attendance/models/attendance_repository.dart';
import '../features/classes/models/classes_repository.dart';
import '../features/classes/models/teaching_class.dart';
import '../features/communication/models/communication_repository.dart';
import '../features/communication/models/message_thread.dart';
import '../features/dashboard/models/dashboard_data.dart';
import '../features/dashboard/models/dashboard_repository.dart';
import '../features/gradebook/models/gradebook_data.dart';
import '../features/gradebook/models/gradebook_repository.dart';
import '../features/performance/models/performance_data.dart';
import '../features/performance/models/performance_repository.dart';
import '../features/quiz/models/quiz_models.dart';
import 'teacher_api_service.dart';

/// Single data gateway for the Teacher module. Every Teacher controller depends
/// on this class (never on [TeacherApiService] or [ApiService] directly).
///
/// Flip [_useMock] to `false` to route through the live [TeacherApiService];
/// while `true` the methods return the bundled per-feature mock fixtures.
class TeacherRepository {
  final TeacherApiService _api;

  final _dashboardMock = DashboardRepository();
  final _classesMock = ClassesRepository();
  final _attendanceMock = AttendanceRepository();
  final _assignmentsMock = AssignmentsRepository();
  final _communicationMock = CommunicationRepository();
  final _gradebookMock = GradebookRepository();
  final _performanceMock = PerformanceRepository();

  TeacherRepository({TeacherApiService? api})
      : _api = api ?? TeacherApiService();

  // Aggregate/complex + write features (dashboard/attendance/gradebook/
  // performance/communication, createHomework/createExam) have no usable
  // backend mapping yet → stay on mock. Writes need real section/subject/class
  // UUIDs the forms don't collect.
  static const bool _useMock = true;

  // Per-feature live flags: these map to real `/schools/{id}/...` reads (with
  // documented field losses — see TeacherApiService). Flip to false to revert.
  static const bool _liveClasses = true;
  static const bool _liveAssignments = true;
  static const bool _liveCommunication = true;

  Future<ApiResponse<DashboardData>> loadDashboard() =>
      _useMock ? _dashboardMock.load() : _api.fetchDashboard();

  Future<ApiResponse<List<TeachingClass>>> loadClasses() =>
      _liveClasses ? _api.fetchClasses() : _classesMock.fetch();

  /// Distinct subject names for the school (live only — no mock fixture).
  Future<ApiResponse<List<String>>> loadSubjects() => _api.fetchSubjects();

  Future<ApiResponse<List<AttendanceClass>>> loadAttendanceClasses() =>
      _useMock ? _attendanceMock.fetchClasses() : _api.fetchAttendanceClasses();

  Future<ApiResponse<List<AttendanceStudent>>> loadAttendanceStudents(
          String classId) =>
      _useMock
          ? _attendanceMock.fetchStudents(classId)
          : _api.fetchAttendanceStudents(classId);

  Future<ApiResponse<void>> saveAttendanceMarks(
      String classId, Map<String, String> marks) async {
    if (!_useMock) return _api.saveAttendanceMarks(classId, marks);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return ApiResponse.ok(null);
  }

  Future<ApiResponse<AssignmentsData>> loadAssignments({String? classFilter}) =>
      _liveAssignments
          ? _api.fetchAssignments(classFilter: classFilter)
          : _assignmentsMock.load(classFilter: classFilter);

  Future<ApiResponse<List<MessageThread>>> loadMessages({
    String query = '',
    ThreadParty? party,
  }) =>
      _liveCommunication
          ? _api.fetchMessages(query: query, party: party?.name)
          : _communicationMock.fetch(query: query, party: party);

  Future<ApiResponse<Gradebook>> loadGradebook(String? examId) =>
      _useMock
          ? _gradebookMock.load(examId)
          : _api.fetchGradebook(examId ?? '');

  Future<ApiResponse<StudentDetail>> loadStudentPerformance(
          String? studentId) =>
      _useMock
          ? _performanceMock.load(studentId)
          : _api.fetchStudentPerformance(studentId ?? '');

  Future<ApiResponse<void>> createHomework(Map<String, dynamic> payload) async {
    if (!_useMock) return _api.createHomework(payload);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return ApiResponse.ok(null);
  }

  Future<ApiResponse<void>> createExam(Map<String, dynamic> payload) async {
    if (!_useMock) return _api.createExam(payload);
    await Future<void>.delayed(const Duration(milliseconds: 450));
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
}
