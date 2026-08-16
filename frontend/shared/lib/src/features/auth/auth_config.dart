import 'api_institution_loader.dart';
import 'models/institution.dart';

/// App-level configuration the shared auth flow reads at runtime.
///
/// Each portal sets these once at boot (before `runApp`) so the *shared* login /
/// forgot / OTP / reset screens behave correctly per app without the `shared`
/// package needing to know about app-specific routes or data sources.
///
/// ```dart
/// // school_portal/lib/main.dart
/// AuthConfig.homeRoute = SchoolRoutes.dashboard;
/// AuthConfig.requireInstitution = true;
/// AuthConfig.institutionsLoader = apiInstitutionLoader; // optional
///
/// // admin_portal/lib/main.dart
/// AuthConfig.homeRoute = AdminRoutes.dashboard;
/// AuthConfig.requireInstitution = false; // super-admin: no institution picker
/// ```
class AuthConfig {
  AuthConfig._();

  /// Route to land on after a successful login (`Get.offAllNamed`). Used as the
  /// fallback when [homeRouteResolver] is null or returns null.
  static String homeRoute = '/home';

  /// Optional role-aware landing resolver. Given the signed-in user's role
  /// codes (from `/auth/me` → `roles[].code`), return the route to open. Return
  /// null to fall back to [homeRoute]. Each portal wires this at boot so the
  /// *shared* login can route headmaster/teacher/student/guardian to the right
  /// module shell without `shared` knowing app-specific routes.
  static String? Function(List<String> roleCodes)? homeRouteResolver;

  /// When true the login screen shows + requires the institution dropdown.
  /// School portal → true; admin (super-admin) portal → false.
  static bool requireInstitution = true;

  /// When false the forgot-password / OTP / reset flow is treated as
  /// unavailable (the backend endpoints don't exist yet): the screens show a
  /// graceful "not available" message instead of calling a 404 endpoint.
  static bool passwordResetEnabled = true;

  /// Optional loader for the institution dropdown. Return the schools the user
  /// can pick from. Defaults to [apiInstitutionLoader]; set to `null` to hide
  /// any network call (dropdown then stays empty until populated manually).
  static InstitutionLoader? institutionsLoader = apiInstitutionLoader;

  /// Product name shown in headers/footers.
  static String appName = 'Meri Taleem';

  /// Asset key for the logo shown above the login form, e.g.
  /// `'assets/images/app_icon.png'`. Each portal sets this at boot because the
  /// asset lives in the app package, not in `shared`. When null the login
  /// screen falls back to a tinted icon mark.
  static String? logoAsset;

  /// Copyright year shown in the footer.
  static String copyrightYear = '2024';
}
