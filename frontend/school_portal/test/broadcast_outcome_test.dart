import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/features/announcements/components/announcement_card.dart';
import 'package:school_portal/school/modules/headmaster/features/announcements/models/announcement.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_api_service.dart';
import 'package:school_portal/school/modules/teacher/data/teacher_repository.dart';
import 'package:school_portal/school/modules/teacher/features/classes/models/my_class.dart';
import 'package:school_portal/school/modules/teacher/features/communication/controller/create_announcement_controller.dart';
import 'package:school_portal/school/modules/teacher/features/communication/view/create_announcement_view.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

const outcomes = {
  'uncertain': 'Delivery needs review',
  'simulated': 'Simulated — not sent',
  'accepted': 'Accepted by provider',
  'pending': 'Pending delivery',
  'failed': 'Delivery failed',
  'partial': 'Partially accepted',
  'sent': 'Legacy send — unconfirmed',
  'unknown': 'Delivery unconfirmed',
};

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
  });
  tearDown(() => Get.reset());

  for (final width in [320.0, 1200.0]) {
    testWidgets(
      'broadcast outcome remains explicit at $width with large text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final entry in outcomes.entries) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: const TextScaler.linear(1.4),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: AnnouncementCard(
                      announcement: Announcement(
                        id: 'message',
                        scope: AnnouncementScope.schoolWide,
                        timestamp: 'September 15, 2026',
                        title: 'School update',
                        body: 'Please review this update.',
                        deliveryStatus: entry.key,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(entry.value), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  test(
    'both broadcast data paths preserve outcomes instead of claiming sent',
    () async {
      final store = _Store();
      var status = 'simulated';
      final api = ApiService(
        store: store,
        client: MockClient((r) async {
          final row = {
            'id': 'message',
            'body': 'Test',
            'audience_type': 'students',
            'status': status,
          };
          return http.Response(
            jsonEncode(r.method == 'POST' ? row : [row]),
            r.method == 'POST' ? 201 : 200,
          );
        }),
      );
      Get.put(
        AuthService(api: api, store: store)
          ..currentUser.value = {
            'id': 'teacher',
            'school_id': 'school',
            'roles': ['teacher'],
          },
      );
      final controller =
          CreateAnnouncementController(
              repo: TeacherRepository(api: TeacherApiService(api: api)),
            )
            ..body.value = 'Test'
            ..audience.value = AnnouncementAudience.students;
      final headmaster = HeadmasterApiService(api: api);
      for (final entry in outcomes.entries) {
        status = entry.key;
        expect(await controller.submit(), isTrue);
        expect(controller.outcome.label, entry.value);
        final list = await headmaster.fetchAnnouncements();
        expect(list.success, isTrue);
        expect(list.data!.single.deliveryStatus, entry.key);
      }
    },
  );

  testWidgets(
    'teacher audience selection works with the grouped radio control',
    (tester) async {
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      Get.put(
        AuthService(api: api, store: store)
          ..currentUser.value = {'id': 'teacher', 'school_id': 'school'},
      );
      final controller = Get.put(
        CreateAnnouncementController(
          repo: TeacherRepository(api: TeacherApiService(api: api)),
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light(),
          home: const CreateAnnouncementView(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('All guardians'));
      await tester.pumpAndSettle();
      expect(controller.audience.value, AnnouncementAudience.guardians);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'section recovery clears stale choices and blocks a section send',
    () async {
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((_) async => http.Response('Unavailable', 503)),
      );
      Get.put(
        AuthService(api: api, store: store)
          ..currentUser.value = {
            'id': 'teacher',
            'school_id': 'school',
            'roles': ['teacher'],
          },
      );
      final controller =
          CreateAnnouncementController(
              repo: TeacherRepository(api: TeacherApiService(api: api)),
            )
            ..sections.addAll([
              const MyClass(
                sectionId: 'stale-section',
                className: 'Grade 8',
                sectionName: 'A',
                studentCount: 1,
                subjects: ['Mathematics'],
                periodsPerWeek: 1,
              ),
            ])
            ..sectionId.value = 'stale-section'
            ..body.value = 'Please read this';

      await controller.loadSections();

      expect(controller.sections, isEmpty);
      expect(controller.sectionId.value, isNull);
      expect(controller.sectionsError.value, isNotNull);
      expect(await controller.submit(), isFalse);
      expect(controller.error.value, contains('Reconnect'));
    },
  );
}
