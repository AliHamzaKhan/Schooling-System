/// Route name constants owned by the Guardian (parent) module. Pages live in
/// [GuardianPages] — see the corresponding `guardian_pages.dart`.
class GuardianRoutes {
  GuardianRoutes._();

  /// Base path prefix for every screen in this module.
  static const _base = '/guardian';

  static const shell = _base; // bottom-nav shell
  static const childSelection = '$_base/children';
  static const fees = '$_base/fees';
  static const exams = '$_base/exams';
  static const meetings = '$_base/meetings';
  static const reportCard = '$_base/report-card';
  static const timetable = '$_base/timetable';
  static const notifications = '$_base/notifications';
  static const leave = '$_base/leave';
}
