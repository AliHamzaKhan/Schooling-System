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
  static const schoolOverview = '$_base/overview';
  static const approvals = '$_base/approvals'; // full pending-approvals list
  static const overduePayments = '$_base/fees/overdue'; // full overdue list
  static const upcomingEvents = '$_base/overview/events'; // full events list
  static const students = '$_base/students';
  // Shared staff drill-down (also navigated to from the Teacher module):
  // class → sections → students → 360° student report.
  static const studentReport = '$_base/students/report';
  static const messageHistory = '$_base/students/report/messages';
  static const sectionStudents = '$_base/sections/students';
  static const classStudents = '$_base/classes/students';
  static const teachers = '$_base/teachers';
  static const guardians = '$_base/guardians';
  static const timetable = '$_base/timetable';
  static const announcements = '$_base/announcements';
  static const analytics = '$_base/analytics';
  static const settings = '$_base/settings';
  static const salary = '$_base/salary';
}
