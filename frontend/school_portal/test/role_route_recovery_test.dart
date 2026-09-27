import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/config/teacher_pages.dart';
import 'package:school_portal/school/config/student_pages.dart';
import 'package:school_portal/school/config/guardian_pages.dart';
import 'package:school_portal/school/config/driver_pages.dart';
import 'package:school_portal/school/config/headmaster_pages.dart';
import 'package:school_portal/school/config/student_routes.dart';
import 'package:school_portal/school/config/teacher_routes.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/student/data/student_repository.dart';

class TestStore extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}
void main() {
  late AuthService auth;
  late List<String> requests;
  final groups = <String, List<GetPage> Function()>{
    'teacher': () => TeacherPages.pages, 'student': () => StudentPages.pages,
    'guardian': () => GuardianPages.pages, 'driver': () => DriverPages.pages,
    'headmaster': () => HeadmasterPages.pages,
  };
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
    requests = [];
    final store = TestStore();
    final api = ApiService(store: store, client: MockClient((r) async {
      requests.add(r.url.path);
      return http.Response(jsonEncode([]), 200);
    }));
    auth = AuthService(api: api, store: store)..restoreAttempted = true;
    auth.isLoggedIn.value = true;
    Get.put(auth); Get.put(api);
    SessionNavigation.routes = groups.values.expand((pages) => pages()).map((p) => p.name).toSet();
  });
  tearDown(() { Get.reset(); SessionNavigation.routes = {}; });
  test('every registered school route rejects other roles and preserves unauthenticated target', () {
    for (final entry in groups.entries) {
      for (final page in entry.value()) {
        final guard = page.middlewares!.whereType<RoleRouteGuard>().single;
        auth.currentUser.value = {'roles': [{'code': entry.key}]};
        auth.isLoggedIn.value = true;
        expect(guard.redirect(page.name), isNull, reason: page.name);
        auth.currentUser.value = {'roles': [{'code': 'unassigned'}]};
        expect(guard.redirect(page.name)!.name, AuthRoutes.accessDenied, reason: page.name);
        auth.isLoggedIn.value = false;
        expect(guard.redirect(page.name)!.name, SessionNavigation.loginFor(page.name), reason: page.name);
      }
    }
    expect(requests, isEmpty);
  });
  testWidgets('cold course URL recovers without a cast exception or shell dependency', (t) async {
    auth.currentUser.value = {'id': 'student', 'school_id': 'school', 'roles': [{'code': 'student'}]};
    await t.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: [
      GetPage(name: '/boot', page: () => const SizedBox()), ...StudentPages.pages,
    ]));
    Get.toNamed(StudentRoutes.courseBook);
    await t.pumpAndSettle();
    expect(find.byType(RouteContextMissingView), findsOneWidget);
    expect(Get.isRegistered<StudentRepository>(), isTrue);
    expect(requests, isEmpty);
    expect(t.takeException(), isNull);
  });
  testWidgets('cold teacher gradebook loads its list without visiting the shell', (t) async {
    auth.currentUser.value = {'id': 'teacher', 'school_id': 'school', 'roles': [{'code': 'teacher'}]};
    await t.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: [
      GetPage(name: '/boot', page: () => const SizedBox()), ...TeacherPages.pages,
    ]));
    Get.toNamed(TeacherRoutes.gradebook);
    await t.pumpAndSettle();
    expect(Get.isRegistered<TeacherRepository>(), isTrue);
    expect(requests, isNotEmpty);
    expect(t.takeException(), isNull);
    Get.back(); await t.pumpAndSettle();
    expect(Get.currentRoute, '/boot');
  });
}
