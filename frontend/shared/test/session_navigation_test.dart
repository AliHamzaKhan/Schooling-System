import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
void main() {
  tearDown(Get.reset);
  setUp(() { SessionNavigation.routes = {'/teacher', '/teacher/report', '/headmaster', AuthRoutes.login, AuthRoutes.restore}; });
  test('login return preserves query and rejects external, auth and unknown paths', () {
    expect(SessionNavigation.loginFor('/teacher/report?student_id=123'), '/login?returnTo=%2Fteacher%2Freport%3Fstudent_id%3D123');
    for (final target in ['https://evil.test', '//evil.test', '/unknown', '/login', '/restore-session', '/teacher#evil', '/\\evil']) {
      expect(SessionNavigation.safeTarget(target), isNull);
    }
  });
  test('cold routes restore first; unauthenticated routes preserve target; wrong roles denied', () {
    final store = DataStoreService();
    final auth = Get.put(AuthService(api: ApiService(store: store), store: store));
    final guard = RoleRouteGuard({'teacher'});
    expect(guard.redirect('/teacher/report?student_id=123')!.name, startsWith('/restore-session?returnTo='));
    auth.restoreAttempted = true;
    expect(guard.redirect('/teacher')!.name, '/login?returnTo=%2Fteacher');
    auth.isLoggedIn.value = true;
    auth.currentUser.value = {'roles': [{'code': 'student'}]};
    expect(guard.redirect('/teacher')!.name, AuthRoutes.accessDenied);
    auth.currentUser.value = {'roles': [{'code': 'teacher'}]};
    expect(guard.redirect('/teacher'), isNull);
  });
}
