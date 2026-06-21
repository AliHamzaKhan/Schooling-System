/// Central registry of every backend path used by the Teacher module. No
/// endpoint string is hardcoded inside the API service or repository.
class TeacherEndpoints {
  TeacherEndpoints._();

  static const _base = '/teacher';

  static const dashboard = '$_base/dashboard';
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
  static String studentPerformance(String studentId) =>
      '$_base/students/$studentId/performance';
}
