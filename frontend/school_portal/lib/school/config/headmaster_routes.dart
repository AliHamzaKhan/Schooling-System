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
  static const students = '$_base/students';
  static const teachers = '$_base/teachers';
  static const guardians = '$_base/guardians';
  static const timetable = '$_base/timetable';
  static const announcements = '$_base/announcements';
  static const analytics = '$_base/analytics';
}
