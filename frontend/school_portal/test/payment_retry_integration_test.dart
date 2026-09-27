import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/fees/view/record_payment_view.dart';

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

  for (final layout in [(320.0, 1.0), (320.0, 1.4), (1280.0, 1.0)]) {
    testWidgets(
      'payment screen blocks repeated taps at ${layout.$1} width / ${layout.$2} text',
      (tester) async {
        tester.view.physicalSize = Size(layout.$1, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final completed = Completer<http.Response>();
        var posts = 0;
        final store = _Store();
        final api = ApiService(
          store: store,
          client: MockClient((request) async {
            if (request.method == 'POST') {
              posts++;
              return completed.future;
            }
            return http.Response(
              jsonEncode({
                'total': 1,
                'items': [
                  {
                    'student_id': 'student',
                    'full_name': 'Test Student',
                    'outstanding_total': 100,
                    'paid_total': 0,
                    'has_overdue': false,
                    'invoices': [
                      {
                        'id': 'invoice',
                        'title': 'Tuition',
                        'amount': 100,
                        'amount_paid': 0,
                        'balance': 100,
                        'status': 'unpaid',
                        'due_date': '2027-01-01',
                      },
                    ],
                  },
                ],
              }),
              200,
            );
          }),
        );
        final auth = AuthService(api: api, store: store);
        auth.currentUser.value = {'id': 'user', 'school_id': 'school'};
        Get.put<AuthService>(auth);
        Get.put<HeadmasterRepository>(
          HeadmasterRepository(api: HeadmasterApiService(api: api)),
        );
        await tester.pumpWidget(
          GetMaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(layout.$2)),
              child: child!,
            ),
            home: const RecordPaymentView(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test Student'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Mark as paid'));
        await tester.tap(find.text('Mark as paid'));
        await tester.pumpAndSettle();
        expect(find.text('Record manual payment'), findsOneWidget);
        await tester.ensureVisible(find.text('Record payment'));
        await tester.tap(find.text('Record payment'));
        await tester.pump();
        final recording = find.widgetWithText(FilledButton, 'Recording…');
        expect(recording, findsOneWidget);
        expect(tester.widget<FilledButton>(recording).onPressed, isNull);
        await tester.tap(find.text('Recording…'));
        await tester.pump();
        expect(posts, 1);
        completed.complete(http.Response('{}', 503));
        await tester.pumpAndSettle();
        expect(find.text('Payment not confirmed'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );
  }

  test(
    'headmaster payment retains its header/body through auth refresh and lost response',
    () async {
      final requests = <http.Request>[];
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((request) async {
          requests.add(request);
          if (requests.length == 1) return http.Response('{}', 401);
          if (requests.length == 2) {
            throw http.ClientException('connection lost');
          }
          return http.Response(
            jsonEncode({'id': request.headers['Idempotency-Key']}),
            201,
          );
        }),
      );
      api.tokenRefresher = () async => true;
      final auth = AuthService(api: api, store: store);
      auth.currentUser.value = {'id': 'user', 'school_id': 'school'};
      Get.put<AuthService>(auth);
      final service = HeadmasterApiService(api: api);
      final first = await service.recordPayment(
        invoiceId: 'invoice',
        amount: 30,
        method: 'cash',
        paidOn: DateTime(2026, 9, 14),
      );
      expect(first.isNetworkError, isTrue);
      final retry = await service.recordPayment(
        invoiceId: 'invoice',
        amount: 70,
        method: 'cash',
        paidOn: DateTime(2026, 9, 15),
      );
      expect(retry.success, isTrue);
      expect(requests.length, 3);
      expect(
        requests.map((r) => r.headers['Idempotency-Key']).toSet().length,
        1,
      );
      expect(requests.map((r) => r.body).toSet().length, 1);
      expect(jsonDecode(requests.last.body)['amount'], 30);
      expect(jsonDecode(requests.last.body)['paid_on'], '2026-09-14');
      expect(
        requests.last.url.path,
        '/api/v1/schools/school/fees/invoices/invoice/payments',
      );
    },
  );
}
