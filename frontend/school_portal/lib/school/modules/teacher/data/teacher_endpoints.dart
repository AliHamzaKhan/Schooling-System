/// Central registry of every backend path used by the Teacher module. No
/// endpoint string is hardcoded inside the API service or repository.
class TeacherEndpoints {
  TeacherEndpoints._();

  static const _base = '/teacher';

  // Live, school-scoped teacher home. See myDashboard() below.
  static const classes = '$_base/classes';

  static const attendanceClasses = '$_base/attendance/classes';
  static String attendanceStudents(String classId) =>
      '$_base/attendance/classes/$classId/students';
  static String attendanceMarks(String classId) =>
      '$_base/attendance/classes/$classId/marks';

  static const assignments = '$_base/assignments';
  static const homework = '$_base/homework';
  static const exams = '$_base/exams';
  static const messages = '$_base/messages';

  static String gradebook(String examId) => '$_base/gradebook/$examId';
  static String studentPerformance(String schoolId, String studentId) =>
      '/schools/$schoolId/academic/students/$studentId/performance';

  // ── Live, school-scoped backend paths (`/schools/{school_id}/...`) ──
  // Wired teacher reads. The aggregate paths above stay for the still-mock
  // dashboard/attendance/gradebook/performance/communication features.
  static String academicClasses(String schoolId) =>
      '/schools/$schoolId/academic/classes';
  static String academicSubjects(String schoolId) =>
      '/schools/$schoolId/academic/subjects';

  /// The signed-in teacher's own weekly timetable.
  static String sectionPerformance(String schoolId, String sectionId) =>
      '/schools/$schoolId/academic/sections/$sectionId/performance';

  static String sectionStudents(String schoolId, String sectionId) =>
      '/schools/$schoolId/sections/$sectionId/students';

  static String attendance(String schoolId) => '/schools/$schoolId/attendance';

  static String schoolExams(String schoolId) => '/schools/$schoolId/exams';
  static String examPapers(String schoolId, String examId) =>
      '/schools/$schoolId/exams/$examId/papers';
  static String paperGradebook(String schoolId, String paperId) =>
      '/schools/$schoolId/exams/papers/$paperId/gradebook';
  static String paperMarks(String schoolId, String paperId) =>
      '/schools/$schoolId/exams/papers/$paperId/marks';

  static String myDashboard(String schoolId) =>
      '/schools/$schoolId/academic/me/dashboard';

  static String myTimetable(String schoolId) =>
      '/schools/$schoolId/academic/me/timetable';
  static String mySections(String schoolId) =>
      '/schools/$schoolId/academic/me/sections';
  static String academicClassSections(String schoolId, String classId) =>
      '/schools/$schoolId/academic/classes/$classId/sections';
  static String homeworkAssignments(String schoolId) =>
      '/schools/$schoolId/homework/assignments';
  static String broadcasts(String schoolId) =>
      '/schools/$schoolId/communication/broadcasts';

  // ── Quizzes ──
  static String quizzes(String schoolId) => '/schools/$schoolId/quizzes';
  static String quizQuestions(String schoolId, String quizId) =>
      '/schools/$schoolId/quizzes/$quizId/questions';
  static String quizPublish(String schoolId, String quizId) =>
      '/schools/$schoolId/quizzes/$quizId/publish';
  static String quizPerformance(String schoolId, String quizId) =>
      '/schools/$schoolId/quizzes/$quizId/performance';
  static String quizGenerateQuestions(String schoolId) =>
      '/schools/$schoolId/quizzes/generate-questions';
  static String quizSectionStudents(String schoolId, String sectionId) =>
      '/schools/$schoolId/quizzes/sections/$sectionId/students';

  // ── Homework grading ──
  static String assignmentSubmissions(String schoolId, String assignmentId) =>
      '/schools/$schoolId/homework/assignments/$assignmentId/submissions';
  static String gradeSubmission(String schoolId, String submissionId) =>
      '/schools/$schoolId/homework/submissions/$submissionId/grade';

  // ── Leave review (class teacher) ──
  static String leaveForReview(String schoolId) =>
      '/schools/$schoolId/leave/requests/for-review';
  static String leaveApprove(String schoolId, String leaveId) =>
      '/schools/$schoolId/leave/requests/$leaveId/approve';
  static String leaveReject(String schoolId, String leaveId) =>
      '/schools/$schoolId/leave/requests/$leaveId/reject';
}
