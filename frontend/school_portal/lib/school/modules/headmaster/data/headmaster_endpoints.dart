/// Central registry of every backend path used by the Headmaster module. No
/// endpoint string is hardcoded inside the API service or repository.
class HeadmasterEndpoints {
  HeadmasterEndpoints._();

  static const _base = '/headmaster';

  static const dashboard = '$_base/dashboard';
  static const overview = '$_base/overview';
  static const attendance = '$_base/attendance';
  static const exams = '$_base/exams';
  static const fees = '$_base/fees';
  static const classes = '$_base/classes';
  static const timetable = '$_base/timetable';
  static const reports = '$_base/reports';
  static const announcements = '$_base/announcements';
  static const teachers = '$_base/teachers';
  static const students = '$_base/students';
  static const guardians = '$_base/guardians';
}
