/// Route name constants owned by the Teacher module. Pages live in
/// [TeacherPages] — see the corresponding `teacher_pages.dart`.
class TeacherRoutes {
  TeacherRoutes._();

  /// Base path prefix for every screen in this module.
  static const _base = '/teacher';

  static const shell = _base;                              // bottom-nav shell
  static const attendanceMark = '$_base/attendance/mark';  // per-class marking
  static const createHomework = '$_base/homework/new';
  static const createExam = '$_base/exams/new';
  static const quizzes = '$_base/quizzes';
  static const createQuiz = '$_base/quizzes/new';
  static const quizPerformance = '$_base/quizzes/performance';
  static const chat = '$_base/chat';                       // Communication Center
  static const createAnnouncement = '$_base/chat/announce'; // compose broadcast
  static const messages = '$_base/messages';               // two-way direct messages
  static const gradebook = '$_base/gradebook/marks';       // Marks Entry
  static const studentPerformance = '$_base/performance/student';
  static const calendar = '$_base/calendar';               // schedule calendar
  static const classDetail = '$_base/classes/detail';      // single class detail
  static const sectionStudents = '$_base/classes/students';
  static const studentReport = '$_base/students/report';
  static const leaveReview = '$_base/leave';                // class-teacher review
  static const grading = '$_base/assignments/grade';        // submissions + grading
}
