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

  // ── Live, school-scoped backend paths (`/schools/{school_id}/...`) ──
  // Used by the wired features (people directories, classes, exams). The
  // aggregate paths above remain for the still-mock dashboard/overview/etc.
  static String users(String schoolId) => '/schools/$schoolId/users';
  static String academicClasses(String schoolId) =>
      '/schools/$schoolId/academic/classes';
  static String examsList(String schoolId) => '/schools/$schoolId/exams';

  // Aggregate report endpoints (read-only) now backed by the API.
  static String school(String schoolId) => '/schools/$schoolId';
  static String reportsOverview(String schoolId) =>
      '/schools/$schoolId/reports/overview';
  static String reportsAttendance(String schoolId) =>
      '/schools/$schoolId/reports/attendance';
  static String reportsAcademic(String schoolId) =>
      '/schools/$schoolId/reports/academic';
  static String reportsFinance(String schoolId) =>
      '/schools/$schoolId/reports/finance';
  static String reportsEnrollment(String schoolId) =>
      '/schools/$schoolId/reports/enrollment';
  static String feesInvoices(String schoolId) =>
      '/schools/$schoolId/fees/invoices';
  static String academicTimetable(String schoolId) =>
      '/schools/$schoolId/academic/timetable';
  static String academicSubjects(String schoolId) =>
      '/schools/$schoolId/academic/subjects';
  static String broadcasts(String schoolId) =>
      '/schools/$schoolId/communication/broadcasts';
}
