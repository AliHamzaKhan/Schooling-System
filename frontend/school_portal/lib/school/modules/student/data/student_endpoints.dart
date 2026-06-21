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
}
