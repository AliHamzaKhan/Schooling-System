import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/config/teacher_pages.dart';
import 'package:school_portal/school/config/teacher_routes.dart';
import 'package:school_portal/school/config/headmaster_pages.dart';
import 'package:school_portal/school/config/headmaster_routes.dart';
import 'package:school_portal/school/modules/headmaster/features/student_report/controller/student_report_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/student_report/view/student_report_view.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'token';
}

void main() {
  late AuthService auth;
  late List<http.Request> requests;
  var denyReport = false;
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
    requests = [];
    denyReport = false;
    final store = _Store();
    final api = ApiService(store: store, client: MockClient((r) async {
      requests.add(r);
      if (denyReport) return http.Response('{"detail":"Report access denied"}', 403);
      final Object body = r.url.path.endsWith('/students')
          ? [{'student_id': 'student', 'name': 'Test Learner'}]
          : {'student_id': 'student', 'student_name': 'Test Learner'};
      return http.Response(jsonEncode(body), 200);
    }));
    auth = AuthService(api: api, store: store);
    auth.isLoggedIn.value = true;
    auth.currentUser.value = {'id': 'teacher', 'school_id': 'school', 'roles': [{'code': 'teacher'}]};
    Get.put<ApiService>(api);
    Get.put<AuthService>(auth);
  });
  tearDown(() => Get.reset());

  List<GetPage> pages() => [
    GetPage(name: '/boot', page: () => const SizedBox()),
    GetPage(name: AuthRoutes.login, page: () => const Text('Login')),
    GetPage(name: AuthRoutes.accessDenied, page: () => const Text('Denied')),
    ...TeacherPages.pages.where((p) => [TeacherRoutes.studentReport, TeacherRoutes.sectionStudents].contains(p.name)),
  ];

  test('teacher-owned read routes do not relax headmaster boundaries', () {
    for (final name in [TeacherRoutes.studentReport, TeacherRoutes.sectionStudents]) {
      final page = TeacherPages.pages.singleWhere((p) => p.name == name);
      final guard = page.middlewares!.whereType<RoleRouteGuard>().single;
      expect(guard.redirect(name), isNull);
      auth.currentUser.value = {'roles': [{'code': 'student'}]};
      expect(guard.redirect(name)!.name, AuthRoutes.accessDenied);
      auth.currentUser.value = {'roles': [{'code': 'teacher'}]};
    }
    final hm = HeadmasterPages.pages.singleWhere((p) => p.name == HeadmasterRoutes.studentReport);
    expect(hm.middlewares!.whereType<RoleRouteGuard>().single.redirect(hm.name)!.name, AuthRoutes.accessDenied);
    auth.isLoggedIn.value = false;
    final teacher = TeacherPages.pages.singleWhere((p) => p.name == TeacherRoutes.studentReport);
    expect(teacher.middlewares!.whereType<RoleRouteGuard>().single.redirect(teacher.name)!.name, AuthRoutes.login);
  });

  testWidgets('direct report URL creates its read-only controller without transient arguments', (tester) async {
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: pages()));
    Get.toNamed('${TeacherRoutes.studentReport}?student_id=student');
    await tester.pumpAndSettle();
    final controller = Get.find<StudentReportController>();
    expect(controller.studentId, 'student');
    expect(controller.readOnly, isTrue);
    expect(tester.widget<StudentReportView>(find.byType(StudentReportView)).readOnly, isTrue);
    expect(requests.single.url.path, '/api/v1/schools/school/reports/students/student');
    await controller.createMeeting(DateTime.now());
    await controller.messageGuardian();
    await controller.sendComplaint();
    expect(requests.every((r) => r.method == 'GET'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section URL opens a learner on the teacher route and supports back', (tester) async {
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: pages()));
    Get.toNamed('${TeacherRoutes.sectionStudents}?section_id=section');
    await tester.pumpAndSettle();
    expect(requests.single.url.path, '/api/v1/schools/school/quizzes/sections/section/students');
    await tester.tap(find.text('Test Learner'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute.startsWith(TeacherRoutes.studentReport), isTrue);
    expect(Get.find<StudentReportController>().studentId, 'student');
    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute.startsWith(TeacherRoutes.sectionStudents), isTrue);
    expect(find.text('Test Learner'), findsOneWidget);
  });

  testWidgets('missing student ID fails locally without requesting another record', (tester) async {
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: pages()));
    Get.toNamed(TeacherRoutes.studentReport);
    await tester.pumpAndSettle();
    expect(find.text('No student selected.'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('denied report refresh clears previously visible student data', (tester) async {
    await tester.pumpWidget(GetMaterialApp(initialRoute: '/boot', getPages: pages()));
    Get.toNamed('${TeacherRoutes.studentReport}?student_id=student');
    await tester.pumpAndSettle();
    final controller = Get.find<StudentReportController>();
    expect(controller.report.value?.studentName, 'Test Learner');
    denyReport = true;
    await controller.load();
    await tester.pumpAndSettle();
    expect(controller.report.value, isNull);
    expect(controller.error.value, isNotNull);
    expect(find.text('Test Learner'), findsNothing);
    controller.studentId = '';
    await controller.load();
    expect(controller.report.value, isNull);
    expect(controller.error.value, 'No student selected.');
  });
}
