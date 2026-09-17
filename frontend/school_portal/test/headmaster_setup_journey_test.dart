import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/students/view/student_registration_view.dart';
import 'package:school_portal/school/modules/headmaster/features/teachers/view/teacher_registration_view.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

Finder _input(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
  description: 'TextField with hint "$hint"',
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
  });
  tearDown(Get.reset);

  Future<void> pumpJourney(
    WidgetTester tester, {
    required Widget page,
    required MockClient client,
  }) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = _Store();
    final api = ApiService(store: store, client: client);
    final auth = AuthService(api: api, store: store);
    auth.isLoggedIn.value = true;
    auth.currentUser.value = {
      'id': 'headmaster-1',
      'school_id': 'school-1',
      'roles': [
        {'code': 'headmaster'},
      ],
    };
    Get.put<ApiService>(api);
    Get.put<AuthService>(auth);
    Get.put<HeadmasterRepository>(
      HeadmasterRepository(api: HeadmasterApiService(api: api)),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        initialRoute: '/origin',
        getPages: [
          GetPage(
            name: '/origin',
            page: () => const Scaffold(body: Text('Setup origin')),
          ),
          GetPage(name: '/setup', page: () => page),
        ],
      ),
    );
    Get.toNamed('/setup');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'student setup distinguishes section failure and resumes enrollment retry',
    (tester) async {
      var sectionReads = 0;
      var studentCreates = 0;
      var enrollmentAttempts = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'GET' && path.endsWith('/academic/classes')) {
          return _json([
            {'id': 'class-1', 'name': 'Grade 8', 'level': 8},
          ]);
        }
        if (request.method == 'GET' &&
            path.endsWith('/academic/classes/class-1/sections')) {
          sectionReads += 1;
          if (sectionReads == 1) {
            return _json({'detail': 'Section service unavailable.'}, 503);
          }
          return _json([
            {'id': 'section-1', 'name': 'A'},
          ]);
        }
        if (request.method == 'POST' && path.endsWith('/users')) {
          studentCreates += 1;
          return _json({'id': 'student-1'});
        }
        if (request.method == 'POST' &&
            path.endsWith('/sections/section-1/students')) {
          enrollmentAttempts += 1;
          if (enrollmentAttempts == 1) {
            return _json({
              'detail': 'Enrollment temporarily unavailable.',
            }, 503);
          }
          return _json({'student_id': 'student-1'});
        }
        return _json({'detail': 'Unexpected ${request.method} $path'}, 500);
      });

      await pumpJourney(
        tester,
        page: const StudentRegistrationView(),
        client: client,
      );

      expect(find.text('Could not load enrollment sections'), findsOneWidget);
      expect(find.text('No enrollment sections'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_input('Student name'), findsOneWidget);

      await tester.enterText(_input('Student name'), 'Test Learner');
      await tester.enterText(_input('student@school.edu'), 'learner@test.edu');
      await tester.enterText(_input('At least 8 characters'), 'password123');
      await tester.ensureVisible(find.text('Admit & Enroll'));
      await tester.tap(find.text('Admit & Enroll'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(
        find.textContaining('enrollment is still pending'),
        findsOneWidget,
      );
      expect(studentCreates, 1);
      expect(enrollmentAttempts, 1);

      await tester.tap(find.text('Admit & Enroll'));
      await tester.pumpAndSettle();
      expect(find.text('Setup origin'), findsOneWidget);
      expect(studentCreates, 1);
      expect(enrollmentAttempts, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'teacher setup resumes salary retry without recreating the account',
    (tester) async {
      var teacherCreates = 0;
      var salaryAttempts = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path.endsWith('/users')) {
          teacherCreates += 1;
          return _json({'id': 'teacher-1'});
        }
        if (request.method == 'POST' && path.endsWith('/hr/staff')) {
          salaryAttempts += 1;
          if (salaryAttempts == 1) {
            return _json({'detail': 'Salary service unavailable.'}, 503);
          }
          return _json({'id': 'staff-1', 'user_id': 'teacher-1'});
        }
        return _json({'detail': 'Unexpected ${request.method} $path'}, 500);
      });

      await pumpJourney(
        tester,
        page: const TeacherRegistrationView(),
        client: client,
      );

      await tester.enterText(_input('Teacher name'), 'Test Teacher');
      await tester.enterText(_input('teacher@school.edu'), 'teacher@test.edu');
      await tester.enterText(_input('At least 8 characters'), 'password123');
      await tester.enterText(_input('e.g. 60000'), '60000');
      await tester.ensureVisible(find.text('Create Teacher'));
      await tester.tap(find.text('Create Teacher'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(
        find.textContaining('salary setup is still pending'),
        findsOneWidget,
      );
      expect(teacherCreates, 1);
      expect(salaryAttempts, 1);

      await tester.tap(find.text('Create Teacher'));
      await tester.pumpAndSettle();
      expect(find.text('Setup origin'), findsOneWidget);
      expect(teacherCreates, 1);
      expect(salaryAttempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
