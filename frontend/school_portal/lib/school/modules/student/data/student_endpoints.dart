/// Central registry of every backend path used by the Student module. No
/// endpoint string is hardcoded inside the API service or repository.
class StudentEndpoints {
  StudentEndpoints._();

  static const _base = '/student';

  static const attendance = '$_base/attendance';
  static const assignments = '$_base/assignments';
  static String assignment(String id) => '$_base/assignments/$id';
  static const exams = '$_base/exams';
  static const notifications = '$_base/notifications';

  // ── Live, school-scoped backend paths (`/schools/{school_id}/...`) ──
  // Wired student features. The aggregate paths above stay for the still-mock
  // attendance / notifications / assignment-detail features.
  static String homeworkAssignments(String schoolId) =>
      '/schools/$schoolId/homework/assignments';
  static String homeworkAssignment(String schoolId, String id) =>
      '/schools/$schoolId/homework/assignments/$id';
  static String examsList(String schoolId) => '/schools/$schoolId/exams';
  static String examPapers(String schoolId, String examId) =>
      '/schools/$schoolId/exams/$examId/papers';
  static String academicSubjects(String schoolId) =>
      '/schools/$schoolId/academic/subjects';
  static String submitAssignment(String schoolId, String assignmentId) =>
      '/schools/$schoolId/homework/assignments/$assignmentId/submissions';
  static String uploads(String schoolId) => '/schools/$schoolId/uploads';

  // ── Quizzes ──
  static String quizzes(String schoolId) => '/schools/$schoolId/quizzes';
  static String quizzesAssigned(String schoolId) =>
      '/schools/$schoolId/quizzes/assigned';
  static String quizDetail(String schoolId, String quizId) =>
      '/schools/$schoolId/quizzes/$quizId';
  static String quizSubmit(String schoolId, String quizId) =>
      '/schools/$schoolId/quizzes/$quizId/attempts/submit';
  static String studentQuizAttempts(String schoolId, String studentId) =>
      '/schools/$schoolId/quizzes/students/$studentId/attempts';
  static String broadcasts(String schoolId) =>
      '/schools/$schoolId/communication/broadcasts';
  static String studentAttendance(String schoolId, String studentId) =>
      '/schools/$schoolId/students/$studentId/attendance';
  static String studentExamResults(String schoolId, String studentId) =>
      '/schools/$schoolId/exams/students/$studentId/results';
  static String studentReportCard(
          String schoolId, String examId, String studentId) =>
      '/schools/$schoolId/exams/$examId/students/$studentId/report-card';
  static String studentTimetable(String schoolId, String studentId) =>
      '/schools/$schoolId/academic/students/$studentId/timetable';

  // ── Courses (reading material) ──
  static String courses(String schoolId) => '/schools/$schoolId/courses';
  static String course(String schoolId, String courseId) =>
      '/schools/$schoolId/courses/$courseId';
  static String courseBooks(String schoolId, String courseId) =>
      '/schools/$schoolId/courses/$courseId/books';
  static String bookChapters(String schoolId, String bookId) =>
      '/schools/$schoolId/courses/books/$bookId/chapters';
  static String chapter(String schoolId, String chapterId) =>
      '/schools/$schoolId/courses/chapters/$chapterId';
  static String courseNotes(String schoolId, String courseId) =>
      '/schools/$schoolId/courses/$courseId/notes';
  static String note(String schoolId, String noteId) =>
      '/schools/$schoolId/courses/notes/$noteId';
  static String readingProgressLookup(String schoolId) =>
      '/schools/$schoolId/courses/progress/lookup';
  static String readingProgress(String schoolId) =>
      '/schools/$schoolId/courses/progress';

  // ── Leave applications ──
  static String leaveRequests(String schoolId) =>
      '/schools/$schoolId/leave/requests';
  static String leaveMine(String schoolId) =>
      '/schools/$schoolId/leave/requests/mine';

  // ── School info ──
  static String schoolInfo(String schoolId) => '/schools/$schoolId/info';

  // ── Transport ──
  static String transportRequests(String schoolId) =>
      '/schools/$schoolId/transport/requests';
  static String transportRequestsMine(String schoolId) =>
      '/schools/$schoolId/transport/requests/mine';
  static String transportTripsActive(String schoolId) =>
      '/schools/$schoolId/transport/trips/active';
  static String transportTripLocation(String schoolId, String tripId) =>
      '/schools/$schoolId/transport/trips/$tripId/location';
  static String transportTripEta(String schoolId, String tripId) =>
      '/schools/$schoolId/transport/trips/$tripId/eta';
}
