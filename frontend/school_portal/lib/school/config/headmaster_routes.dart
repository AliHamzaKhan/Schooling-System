/// Route name constants owned by the Headmaster module.
///
/// Keep these constants here (paths only) and the corresponding `GetPage`
/// declarations in [HeadmasterPages]. Splitting names from pages keeps screens
/// referenceable (`Get.toNamed(HeadmasterRoutes.students)`) without forcing
/// every caller to drag in the page widget + binding imports.
class HeadmasterRoutes {
  HeadmasterRoutes._();

  /// Base path prefix for every screen in this module. Namespacing prevents
  /// collisions with future modules that own their own `/staff/...`,
  /// `/student/...` paths.
  static const _base = '/headmaster';

  static const shell = _base; // the bottom-nav shell itself
  static const approvals = '$_base/approvals'; // full pending-approvals list
  static const overduePayments = '$_base/fees/overdue'; // full overdue list
  static const recordPayment = '$_base/fees/record'; // Record Payment screen
  static const feesRoster = '$_base/fees/students'; // All-students fee roster
  static const financialAdjustments = '$_base/fees/adjustments';
  static const teacherAttendance = '$_base/reports/teacher-attendance';
  static const teacherAttendanceRoster =
      '$_base/reports/teacher-attendance/roster';
  static const upcomingEvents = '$_base/overview/events'; // full events list
  static const students = '$_base/students';
  static const studentRegistration = '$_base/students/register';
  static const teacherRegistration = '$_base/teachers/register';
  // Shared staff drill-down (also navigated to from the Teacher module):
  // class → sections → students → 360° student report.
  static const studentReport = '$_base/students/report';
  static const messageHistory = '$_base/students/report/messages';
  static const sectionStudents = '$_base/sections/students';
  static const classStudents = '$_base/classes/students';
  static const classes = '$_base/classes';
  static const teachers = '$_base/teachers';
  static const guardians = '$_base/guardians';
  static const timetable = '$_base/timetable';
  static const announcements = '$_base/announcements';
  static const analytics = '$_base/analytics';
  static const settings = '$_base/settings';
  static const salary = '$_base/salary';
  static const generatePayslip = '$_base/salary/payslip/new';

  // Transport management (drivers, requests, fleet).
  static const transport = '$_base/transport';

  // Courses authoring.
  static const coursesAdmin = '$_base/courses';
  static const courseContent = '$_base/courses/content';
  static const bookAdmin = '$_base/courses/book';

  // School info authoring.
  static const schoolInfoEdit = '$_base/school-info';

  // Leave review.
  static const leaveReview = '$_base/leave';

  // Examination authoring: categories + student promotion.
  static const examCategories = '$_base/exams/categories';
  static const examTimetable = '$_base/exams/timetable';
  static const promotion = '$_base/exams/promotion';
}
