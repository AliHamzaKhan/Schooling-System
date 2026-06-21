/// Route name constants owned by the Student module. Pages live in
/// [StudentPages] — see the corresponding `student_pages.dart`.
class StudentRoutes {
  StudentRoutes._();

  /// Base path prefix for every screen in this module.
  static const _base = '/student';

  static const shell = _base;                         // bottom-nav shell
  static const assignmentDetail = '$_base/assignments/detail';
  static const notifications = '$_base/notifications';
}
