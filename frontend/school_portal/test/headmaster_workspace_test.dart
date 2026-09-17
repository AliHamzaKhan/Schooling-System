import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/headmaster/controller/headmaster_workspace_controller.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/binding/headmaster_route_binding.dart';
import 'package:school_portal/school/modules/headmaster/features/overview/controller/upcoming_events_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/overview/models/overview_data.dart';
import 'package:school_portal/school/modules/headmaster/features/overview/view/upcoming_events_view.dart';
import 'package:school_portal/school/modules/headmaster/features/dashboard/controller/approvals_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/dashboard/models/dashboard_data.dart';
import 'package:school_portal/school/modules/headmaster/features/dashboard/view/approvals_view.dart';
import 'package:school_portal/school/modules/headmaster/features/attendance/models/teacher_attendance_day.dart';
import 'package:school_portal/school/modules/headmaster/features/attendance/view/teacher_attendance_roster_view.dart';
import 'package:school_portal/school/modules/headmaster/features/exams/controller/exam_timetable_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/courses/controller/book_admin_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/courses/controller/course_content_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/courses/models/admin_course_models.dart';
import 'package:school_portal/school/modules/headmaster/features/student_report/view/section_students_view.dart';
import 'package:school_portal/school/modules/headmaster/features/student_report/view/class_students_view.dart';
import 'package:school_portal/school/modules/headmaster/features/salary/models/salary_models.dart';
import 'package:school_portal/school/modules/headmaster/features/salary/view/generate_payslip_view.dart';
import 'package:school_portal/school/modules/headmaster/models/headmaster_workspace_context.dart';
import 'package:school_portal/school/widgets/portal_tab_scaffold.dart';
import 'package:school_portal/school/config/headmaster_pages.dart';
import 'package:school_portal/school/config/headmaster_routes.dart';
import 'package:school_portal/school/modules/headmaster/routing/headmaster_capability_middleware.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
  });
  tearDown(Get.reset);

  test(
    'workspace context loads capabilities and reports failure honestly',
    () async {
      final success = HeadmasterWorkspaceController(
        loader: () async => ApiResponse.ok(
          const HeadmasterWorkspaceContext(
            schoolName: 'Meri Taleem School',
            activeSession: '2026–27',
            enabledModules: {'student_management', 'timetable'},
          ),
        ),
      );
      await success.load();
      expect(success.context.value?.schoolName, 'Meri Taleem School');
      expect(success.context.value?.enabledModules, contains('timetable'));
      expect(success.error.value, isNull);

      final failure = HeadmasterWorkspaceController(
        loader: () async => ApiResponse.fail('Permission service unavailable.'),
      );
      await failure.load();
      expect(failure.context.value, isNull);
      expect(failure.error.value, 'Permission service unavailable.');
      expect(failure.loading.value, isFalse);
    },
  );

  test('every headmaster route initializes its repository on a cold load', () {
    final store = _Store();
    Get.put<ApiService>(ApiService(store: store));

    expect(
      HeadmasterPages.pages.every(
        (page) => page.bindings.first is HeadmasterRouteBinding,
      ),
      isTrue,
    );

    HeadmasterRouteBinding().dependencies();
    expect(Get.isRegistered<HeadmasterRepository>(), isTrue);

    final students = HeadmasterPages.pages.firstWhere(
      (page) => page.name == HeadmasterRoutes.students,
    );
    final settings = HeadmasterPages.pages.firstWhere(
      (page) => page.name == HeadmasterRoutes.settings,
    );
    expect(
      students.middlewares?.whereType<HeadmasterCapabilityMiddleware>(),
      hasLength(1),
    );
    expect(
      settings.middlewares?.whereType<HeadmasterCapabilityMiddleware>(),
      isEmpty,
    );
  });

  test('drill-down route state prefers URL identifiers and rejects gaps', () {
    final legacyRoster = TeacherAttendanceRosterArgs(
      date: DateTime(2025, 1, 1),
      status: TeacherAttendanceStatus.present,
      title: 'Legacy title',
    );
    final roster = TeacherAttendanceRosterArgs.fromRoute(
      parameters: const {'date': '2026-09-16', 'status': 'late'},
      arguments: legacyRoster,
    );
    expect(roster?.date, DateTime(2026, 9, 16));
    expect(roster?.status, TeacherAttendanceStatus.late);
    expect(roster?.title, 'Late Comers');
    expect(
      TeacherAttendanceRosterArgs.fromRoute(
        parameters: const {'date': 'invalid', 'status': 'absent'},
      ),
      isNull,
    );

    expect(
      ExamTimetableController.categoryIdFromRoute(
        parameters: const {'category_id': 'category-from-url'},
        arguments: const {'categoryId': 'legacy-category'},
      ),
      'category-from-url',
    );
    expect(
      ExamTimetableController.categoryIdFromRoute(
        parameters: const {},
        arguments: const {'categoryId': 'legacy-category'},
      ),
      'legacy-category',
    );
    expect(
      ExamTimetableController.categoryIdFromRoute(parameters: const {}),
      isEmpty,
    );

    expect(
      CourseContentController.courseIdFromRoute(
        parameters: const {'course_id': 'course-from-url'},
        arguments: const AdminCourse(id: 'legacy-course', title: 'Legacy'),
      ),
      'course-from-url',
    );
    expect(
      CourseContentController.courseIdFromRoute(
        parameters: const {},
        arguments: const AdminCourse(id: 'legacy-course', title: 'Legacy'),
      ),
      'legacy-course',
    );
    expect(
      BookAdminController.routeIds(
        parameters: const {
          'course_id': 'course-from-url',
          'book_id': 'book-from-url',
        },
        arguments: const AdminBook(id: 'legacy-book', title: 'Legacy'),
      ),
      (courseId: 'course-from-url', bookId: 'book-from-url'),
    );
    expect(
      BookAdminController.routeIds(
        parameters: const {},
        arguments: const AdminBook(id: 'legacy-book', title: 'Legacy'),
      ),
      (courseId: '', bookId: 'legacy-book'),
    );

    final section = SectionStudentsArgs.fromRoute(
      parameters: const {
        'section_id': 'section-from-url',
        'title': 'Grade 7 · A',
      },
      arguments: const SectionStudentsArgs(
        sectionId: 'legacy-section',
        title: 'Legacy section',
      ),
    );
    expect(section.sectionId, 'section-from-url');
    expect(section.title, 'Grade 7 · A');

    final classStudents = ClassStudentsArgs.fromRoute(
      parameters: const {'class_id': 'class-from-url', 'title': 'Grade 8'},
      arguments: const ClassStudentsArgs(
        classId: 'legacy-class',
        title: 'Legacy class',
      ),
    );
    expect(classStudents.classId, 'class-from-url');
    expect(classStudents.title, 'Grade 8');
    expect(ClassStudentsArgs.fromRoute(parameters: const {}).classId, isEmpty);

    const legacyStaff = SalaryStaff(
      userId: 'legacy-staff',
      name: 'Legacy Teacher',
      email: 'legacy@example.test',
    );
    expect(
      GeneratePayslipArgs.staffIdFromRoute(
        parameters: const {'staff_id': 'staff-from-url'},
        arguments: const GeneratePayslipArgs(legacyStaff),
      ),
      'staff-from-url',
    );
    expect(
      GeneratePayslipArgs.staffIdFromRoute(
        parameters: const {},
        arguments: const GeneratePayslipArgs(legacyStaff),
      ),
      'legacy-staff',
    );
  });

  testWidgets(
    'capability gate builds allowed pages and blocks denied or unknown access',
    (tester) async {
      var childBuilds = 0;
      Widget child(BuildContext context) {
        childBuilds += 1;
        return const Text('Protected students page');
      }

      Future<void> pumpGate(
        Future<ApiResponse<HeadmasterWorkspaceContext>> Function() loader,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: HeadmasterCapabilityGate(
              key: UniqueKey(),
              requiredAny: const {'student_management'},
              loader: loader,
              childBuilder: child,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpGate(
        () async => ApiResponse.ok(
          const HeadmasterWorkspaceContext(
            schoolName: 'Meri Taleem School',
            activeSession: '2026–27',
            enabledModules: {'student_management'},
          ),
        ),
      );
      expect(find.text('Protected students page'), findsOneWidget);
      expect(childBuilds, 1);

      await pumpGate(
        () async => ApiResponse.ok(
          const HeadmasterWorkspaceContext(
            schoolName: 'Meri Taleem School',
            activeSession: '2026–27',
            enabledModules: {'timetable'},
          ),
        ),
      );
      expect(find.text('Module unavailable'), findsOneWidget);
      expect(find.text('Protected students page'), findsNothing);
      expect(childBuilds, 1);

      await pumpGate(
        () async => ApiResponse.fail('Permission service unavailable.'),
      );
      expect(find.text('Could not verify module access'), findsOneWidget);
      expect(find.text('Permission service unavailable.'), findsOneWidget);
      expect(find.text('Protected students page'), findsNothing);
      expect(childBuilds, 1);

      await pumpGate(() async => throw StateError('sensitive internal detail'));
      expect(find.text('Could not verify module access'), findsOneWidget);
      expect(find.textContaining('sensitive internal detail'), findsNothing);
      expect(find.text('Protected students page'), findsNothing);
      expect(childBuilds, 1);
    },
  );

  test(
    'workspace API combines school, session, and effective permissions',
    () async {
      final requestedPaths = <String>[];
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          final path = request.url.path;
          final body = switch (path) {
            _ when path.endsWith('/schools/school-1/profile') => {
              'id': 'school-1',
              'name': 'Meri Taleem School',
              'code': 'MTS',
              'settings': <String, dynamic>{},
            },
            _ when path.endsWith('/schools/school-1/reports/overview') => {
              'active_session': '2026–27',
            },
            _ when path.endsWith('/permissions/me') => {
              'school_id': 'school-1',
              'is_super_admin': false,
              'modules': ['student_management', 'timetable'],
              'matrix': <String, dynamic>{},
            },
            _ => <String, dynamic>{},
          };
          return http.Response.bytes(
            utf8.encode(jsonEncode(body)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final auth = AuthService(api: api, store: store);
      auth.currentUser.value = {'id': 'user-1', 'school_id': 'school-1'};
      Get.put<AuthService>(auth);

      final result = await HeadmasterApiService(
        api: api,
      ).fetchWorkspaceContext();

      expect(
        result.success,
        isTrue,
        reason: '${result.error}; requested: $requestedPaths',
      );
      expect(result.data?.schoolName, 'Meri Taleem School');
      expect(result.data?.activeSession, '2026–27');
      expect(result.data?.enabledModules, {'student_management', 'timetable'});
      expect(requestedPaths, hasLength(3));
      expect(requestedPaths[0], endsWith('/schools/school-1/profile'));
      expect(requestedPaths[1], endsWith('/schools/school-1/reports/overview'));
      expect(requestedPaths[2], endsWith('/permissions/me'));
    },
  );

  testWidgets('desktop shell keeps school and session context visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = DataStoreService();
    final auth = AuthService(
      api: ApiService(store: store),
      store: store,
    );
    auth.currentUser.value = {
      'full_name': 'Ayesha Headmaster',
      'school_name': 'Meri Taleem School',
      'roles': [
        {'code': 'headmaster'},
      ],
    };
    Get.put<AuthService>(auth);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PortalTabScaffold(
          title: 'Headmaster',
          schoolName: 'Meri Taleem School',
          sessionName: '2026–27',
          tabs: const [PortalTab(Icons.dashboard_rounded, 'Dashboard')],
          screens: const [Center(child: Text('Dashboard content'))],
        ),
      ),
    );

    expect(find.text('Meri Taleem School'), findsOneWidget);
    expect(find.text('Session: 2026–27'), findsOneWidget);
    expect(find.text('Dashboard content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'upcoming events cold route loads canonical data and fails closed',
    (tester) async {
      var response = ApiResponse.ok(
        const OverviewData(
          school: SchoolIdentity(
            name: 'Meri Taleem School',
            address: '',
            principal: '',
          ),
          pulse: [],
          events: [
            UpcomingEvent(
              id: 'event-1',
              title: 'Science Fair',
              time: '10:00 AM',
              location: 'Main Hall',
              month: 'OCT',
              day: '12',
              tint: AppColors.primary,
              icon: Icons.event,
            ),
          ],
        ),
      );
      final controller = UpcomingEventsController(loader: () async => response);
      Get.put<UpcomingEventsController>(controller);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const UpcomingEventsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Science Fair'), findsOneWidget);
      expect(find.text('Main Hall'), findsOneWidget);

      response = ApiResponse.fail('Events are unavailable.');
      await controller.load();
      await tester.pump();

      expect(find.text('Science Fair'), findsNothing);
      expect(find.text('Could not load upcoming events'), findsOneWidget);
      expect(find.text('Events are unavailable.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    },
  );

  testWidgets(
    'approval and class list named routes cold-load and preserve back history',
    (tester) async {
      final requests = <http.Request>[];
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((request) async {
          requests.add(request);
          final Object body = request.url.path.endsWith('/sections')
              ? [
                  {'id': 'section-1', 'name': 'A'},
                ]
              : [
                  {'student_id': 'student-1', 'name': 'Test Learner'},
                ];
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
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
      Get.put<ApprovalsController>(
        ApprovalsController(
          loader: () async => ApiResponse.ok(
            DashboardData(
              greeting: '',
              date: '',
              metrics: const [],
              approvals: const [
                PendingApproval(
                  id: 'approval-1',
                  icon: Icons.assignment_outlined,
                  title: 'Review leave request',
                  requestedBy: 'Ayesha Teacher',
                ),
              ],
              announcements: const [],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/route-origin',
          getPages: [
            GetPage(
              name: '/route-origin',
              page: () => const Scaffold(body: Text('Route origin')),
            ),
            GetPage(
              name: HeadmasterRoutes.approvals,
              page: () => const ApprovalsView(),
            ),
            GetPage(
              name: HeadmasterRoutes.classStudents,
              page: () => const ClassStudentsView(),
            ),
          ],
        ),
      );

      Get.toNamed(HeadmasterRoutes.approvals);
      await tester.pumpAndSettle();
      expect(find.text('Review leave request'), findsOneWidget);
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('Route origin'), findsOneWidget);

      Get.toNamed(
        Uri(
          path: HeadmasterRoutes.classStudents,
          queryParameters: const {'class_id': 'class-1', 'title': 'Grade 8'},
        ).toString(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Grade 8 — Students'), findsOneWidget);
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Test Learner'), findsOneWidget);
      expect(requests.map((request) => request.url.path), [
        '/api/v1/schools/school-1/academic/classes/class-1/sections',
        '/api/v1/schools/school-1/quizzes/sections/section-1/students',
      ]);
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('Route origin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
