import 'package:admin_portal/src/app/admin_routes.dart';
import 'package:admin_portal/src/app/portal_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/config/headmaster_pages.dart';
import 'package:school_portal/school/config/headmaster_routes.dart';
import 'package:shared/shared.dart';

void main() {
  test('portal landing is role-aware and privilege ordered', () {
    expect(portalHomeForRoles(['super_admin']), AdminRoutes.home);
    expect(portalHomeForRoles(['headmaster']), HeadmasterRoutes.shell);
    expect(portalHomeForRoles(['headmaster', 'super_admin']), AdminRoutes.home);
    expect(portalHomeForRoles(['teacher']), AuthRoutes.accessDenied);
    expect(portalHomeForRoles([]), AuthRoutes.accessDenied);
  });

  test('every platform-admin route has a role boundary', () {
    expect(
      AdminRoutes.pages.every(
        (page) => page.middlewares?.any((m) => m is RoleRouteGuard) ?? false,
      ),
      isTrue,
    );
  });

  test('every headmaster route has a role boundary', () {
    expect(
      HeadmasterPages.pages.every(
        (page) => page.middlewares?.any((m) => m is RoleRouteGuard) ?? false,
      ),
      isTrue,
    );
  });
}
