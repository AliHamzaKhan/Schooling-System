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
  static const chat = '$_base/chat';                       // Communication Center
  static const gradebook = '$_base/gradebook/marks';       // Marks Entry
  static const studentPerformance = '$_base/performance/student';
}
