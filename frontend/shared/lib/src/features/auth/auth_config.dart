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

  /// Route to land on after a successful login (`Get.offAllNamed`).
  static String homeRoute = '/home';

  /// When true the login screen shows + requires the institution dropdown.
  /// School portal → true; admin (super-admin) portal → false.
  static bool requireInstitution = true;

  /// Optional loader for the institution dropdown. Return the schools the user
  /// can pick from. Defaults to [apiInstitutionLoader]; set to `null` to hide
  /// any network call (dropdown then stays empty until populated manually).
  static InstitutionLoader? institutionsLoader = apiInstitutionLoader;

  /// Product name shown in headers/footers.
  static String appName = 'EduMaster';

  /// Copyright year shown in the footer.
  static String copyrightYear = '2024';
}
