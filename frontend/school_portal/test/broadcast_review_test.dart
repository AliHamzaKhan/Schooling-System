import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/features/announcements/components/delivery_review_dialog.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_api_service.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/communication/controller/create_announcement_controller.dart';
import 'package:school_portal/school/modules/teacher/features/communication/view/create_announcement_view.dart';
import 'package:school_portal/school/modules/teacher/features/classes/models/my_class.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
  });
  tearDown(() => Get.reset());

  for (final teacher in [true, false]) {
    test(
      '${teacher ? 'teacher' : 'headmaster'} preserves identity through auth refresh and lost response',
      () async {
        final store = _Store();
        final requests = <http.Request>[];
        final api = ApiService(
          store: store,
          client: MockClient((request) async {
            requests.add(request);
            if (requests.length == 1) return http.Response('{}', 401);
            if (requests.length == 2) {
              throw http.ClientException('connection lost');
            }
            return http.Response('{"status":"pending"}', 201);
          }),
        );
        api.tokenRefresher = () async => true;
        Get.put(
          AuthService(api: api, store: store)
            ..currentUser.value = {'id': 'user', 'school_id': 'school'},
        );
        final hm = HeadmasterApiService(api: api);
        final ta = TeacherApiService(api: api);
        Future<ApiResponse<dynamic>> send() => teacher
            ? ta.createBroadcast(
                channel: 'push',
                audienceType: 'students',
                body: 'Test',
              )
            : hm.createBroadcast(audienceType: 'students', body: 'Test');
        expect((await send()).isNetworkError, isTrue);
        expect((await send()).success, isTrue);
        expect(requests, hasLength(3));
        expect(
          requests.map((r) => r.headers['Idempotency-Key']).toSet(),
          hasLength(1),
        );
        expect(requests.map((r) => r.body).toSet(), hasLength(1));
      },
    );

    test(
      '${teacher ? 'teacher' : 'headmaster'} retries HTTP with same identity and restores draft',
      () async {
        final store = _Store();
        final requests = <http.Request>[];
        var success = false;
        final api = ApiService(
          store: store,
          client: MockClient((r) async {
            if (r.method == 'GET') return http.Response('[]', 200);
            requests.add(r);
            return success
                ? http.Response('{"id":"message","status":"pending"}', 201)
                : http.Response('{"detail":"unavailable"}', 503);
          }),
        );
        Get.put(
          AuthService(api: api, store: store)
            ..currentUser.value = {'id': 'user', 'school_id': 'school'},
        );
        final hm = HeadmasterApiService(api: api);
        final ta = TeacherApiService(api: api);
        Future<ApiResponse<dynamic>> send(String body) => teacher
            ? ta.createBroadcast(
                channel: 'push',
                audienceType: 'students',
                body: body,
              )
            : hm.createBroadcast(audienceType: 'students', body: body);
        expect((await send('Original')).success, isFalse);
        expect((await send('Edited')).statusCode, 409);
        expect(requests, hasLength(1));
        expect(
          (teacher ? ta.pendingBroadcast : hm.pendingBroadcast)?['body'],
          'Original',
        );
        if (teacher) {
          final controller = CreateAnnouncementController(
            repo: TeacherRepository(api: ta),
          );
          controller.onInit();
          expect(controller.body.value, 'Original');
          expect(controller.audience.value, AnnouncementAudience.students);
          await Future<void>.delayed(Duration.zero);
          controller.onClose();
        }
        success = true;
        expect((await send('Original')).success, isTrue);
        expect(requests[0].headers['Idempotency-Key'], isNotEmpty);
        expect(
          requests[0].headers['Idempotency-Key'],
          requests[1].headers['Idempotency-Key'],
        );
        expect(jsonDecode(requests[0].body), jsonDecode(requests[1].body));
        expect(teacher ? ta.pendingBroadcast : hm.pendingBroadcast, isNull);
        await send('New');
        expect(
          requests[2].headers['Idempotency-Key'],
          isNot(requests[1].headers['Idempotency-Key']),
        );
      },
    );
  }

  testWidgets(
    'restored section remains selectable when no longer in timetable',
    (tester) async {
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      Get.put(
        AuthService(api: api, store: store)
          ..currentUser.value = {'id': 'user', 'school_id': 'school'},
      );
      final controller = Get.put(
        CreateAnnouncementController(
          repo: TeacherRepository(api: TeacherApiService(api: api)),
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(home: const CreateAnnouncementView()),
      );
      await tester.pumpAndSettle();
      controller.sectionId.value = 'original';
      controller.sections.assignAll([
        const MyClass(
          sectionId: 'other',
          className: 'Grade 1',
          sectionName: 'A',
          studentCount: 1,
          subjects: [],
          periodsPerWeek: 1,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Original section (no longer listed)'), findsWidgets);
      expect(controller.sectionId.value, 'original');
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 1200.0]) {
    testWidgets('read-only delivery review paginates and recovers at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final offsets = <int>[];
      var fail = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: DeliveryReviewDialog(
                load: (offset) async {
                  offsets.add(offset);
                  if (fail) return ApiResponse.fail('Review unavailable');
                  return ApiResponse.ok({
                    'message': {
                      'title': 'School announcement',
                      'status': 'uncertain',
                    },
                    'outbox_state': 'needs_review',
                    'worker_attempts': 2,
                    'counts': {'uncertain': 26},
                    'total': 26,
                    'has_more': offset == 0,
                    'items': [
                      {
                        'recipient': 'Recipient ${offset + 1}',
                        'address_label': 'Registered device',
                        'status': 'uncertain',
                      },
                    ],
                  });
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivery review'), findsOneWidget);
      expect(find.text('Manual investigation required'), findsOneWidget);
      expect(find.text('Resend'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(offsets, [0, 25]);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(offsets.last, 0);
      fail = true;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Review unavailable'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Review unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
