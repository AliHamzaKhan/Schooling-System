import 'guardian_routes.dart';
import 'headmaster_routes.dart';
import 'student_routes.dart';
import 'teacher_routes.dart';

/// Centralized top-level route names for the school portal.
///
/// Re-exports each module's "entry" route so the rest of the app navigates
/// through one stable surface (`AppRoutes.home`, `AppRoutes.staffHome`, …)
/// instead of reaching into module-specific files.
class AppRoutes {
  AppRoutes._();

  /// Cold-start screen. Holds the app while the stored session is restored,
  /// then replaces itself with login or the role's module shell — so it is the
  /// `initialRoute` and never a destination anything navigates *to*.
  static const splash = '/splash';

  /// Initial landing route after login. Currently the Headmaster shell; once
  /// other role modules exist this becomes a small role-router that picks the
  /// right module home from the signed-in user's role.
  static const home = HeadmasterRoutes.shell;

  // ── Module entry points (re-exported for discoverability) ───────────
  static const headmaster = HeadmasterRoutes.shell;
  static const teacher = TeacherRoutes.shell;
  static const student = StudentRoutes.shell;
  static const guardian = GuardianRoutes.shell;
  // static const staff = StaffRoutes.shell;
}
