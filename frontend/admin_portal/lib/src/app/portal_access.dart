import 'package:school_portal/school/config/headmaster_routes.dart';
import 'package:shared/shared.dart';

import 'admin_routes.dart';

/// Resolves only roles supported by this portal. The order is deliberate: an
/// account carrying platform and school roles keeps the platform-wide view.
String portalHomeForRoles(List<String> roles) {
  if (roles.contains('super_admin')) return AdminRoutes.home;
  if (roles.contains('headmaster')) return HeadmasterRoutes.shell;
  return AuthRoutes.accessDenied;
}
