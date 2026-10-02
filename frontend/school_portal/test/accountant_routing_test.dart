import 'package:flutter_test/flutter_test.dart';
import 'package:school_portal/school/config/app_routes.dart';
import 'package:school_portal/school/config/role_home.dart';

void main() {
  test('an accountant lands on the finance home', () {
    expect(homeRouteForRoles(['accountant']), AppRoutes.accountant);
    // A headmaster who is also an accountant keeps the headmaster shell.
    expect(homeRouteForRoles(['accountant', 'headmaster']), AppRoutes.headmaster);
  });
}
