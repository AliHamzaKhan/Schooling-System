import 'app_routes.dart';

/// Maps the signed-in user's role codes (from `/auth/me` → `roles[].code`) to
/// the module shell they should land on.
///
/// One definition, three callers — the splash (cold start), the shared login
/// (via `AuthConfig.homeRouteResolver`), and anything that re-lands a user after
/// a session change. Keeping it in one place is what stops a role from being
/// routed correctly on login but incorrectly on relaunch.
///
/// Order matters: a user carrying several roles lands on the most privileged
/// shell they hold. Returns null when no known role matches, so the caller
/// decides the fallback rather than silently landing a student on the
/// headmaster shell.
String? homeRouteForRoles(List<String> roleCodes) {
  if (roleCodes.contains('headmaster')) return AppRoutes.headmaster;
  if (roleCodes.contains('teacher')) return AppRoutes.teacher;
  if (roleCodes.contains('student')) return AppRoutes.student;
  if (roleCodes.contains('guardian')) return AppRoutes.guardian;
  return null;
}
