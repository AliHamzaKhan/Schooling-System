import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/fees/view/financial_adjustments_view.dart';
import 'package:school_portal/school/modules/headmaster/features/fees/view/record_payment_view.dart';
import 'package:shared/shared.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Map<String, dynamic> _adjustment({
  required String id,
  String? decision,
  String? decisionReason,
}) => {
  'id': id,
  'kind': 'credit',
  'target_type': 'invoice',
  'target_id': 'invoice-123456789',
  'proposed_amount': '125.50',
  'currency_code': 'XXX',
  'reason': 'Duplicate bank transfer',
  'decision': decision,
  'decision_reason': decisionReason,
};

void _installRepository(http.Client client) {
  final store = _Store();
  final api = ApiService(store: store, client: client);
  final auth = AuthService(api: api, store: store);
  auth.currentUser.value = {'id': 'headmaster', 'school_id': 'school'};
  Get.put<AuthService>(auth);
  Get.put<HeadmasterRepository>(
    HeadmasterRepository(api: HeadmasterApiService(api: api)),
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    EnvConfig.bootstrap(Environment.debug);
  });
  tearDown(Get.reset);

  testWidgets(
    'invoice adjustment form validates then submits its exact proposal',
    (tester) async {
      final posts = <http.Request>[];
      _installRepository(
        MockClient((request) async {
          if (request.method == 'POST') {
            posts.add(request);
            return http.Response(jsonEncode({'id': 'adjustment-1'}), 201);
          }
          return http.Response(
            jsonEncode({
              'total': 1,
              'items': [
                {
                  'student_id': 'student-1',
                  'full_name': 'Test Student',
                  'outstanding_total': 125.5,
                  'paid_total': 0,
                  'has_overdue': false,
                  'invoices': [
                    {
                      'id': 'invoice-1',
                      'title': 'Tuition',
                      'amount': 125.5,
                      'amount_paid': 0,
                      'balance': 125.5,
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

      await tester.pumpWidget(const GetMaterialApp(home: RecordPaymentView()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Student'));
      await tester.pumpAndSettle();
      final requestButton = find.widgetWithText(
        OutlinedButton,
        'Request refund, credit, or waiver',
      );
      await tester.ensureVisible(requestButton);
      await tester.pumpAndSettle();
      await tester.tap(requestButton);
      await tester.pumpAndSettle();

      expect(find.text('Request invoice adjustment'), findsOneWidget);
      expect(
        find.textContaining('does not change the invoice balance'),
        findsOneWidget,
      );
      final submitButton = find.widgetWithText(
        FilledButton,
        'Submit for Headmaster review',
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      expect(find.text('Give a reason with at least 3 characters.'), findsOneWidget);
      expect(posts, isEmpty);

      await tester.enterText(_field('Proposed amount'), '80.25');
      await tester.enterText(_field('Reason'), 'Verified duplicate payment');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(posts, hasLength(1));
      expect(posts.single.url.path, '/api/v1/schools/school/fees/adjustments');
      expect(jsonDecode(posts.single.body), {
        'kind': 'credit',
        'target_id': 'invoice-1',
        'proposed_amount': '80.25',
        'reason': 'Verified duplicate payment',
      });
      expect(find.text('Adjustment requested'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('review queue requires a reason and records an approval', (
    tester,
  ) async {
    final decisions = <Map<String, dynamic>>[];
    var item = _adjustment(id: 'approval-1');
    _installRepository(
      MockClient((request) async {
        if (request.method == 'POST') {
          decisions.add(
            (jsonDecode(request.body) as Map).cast<String, dynamic>(),
          );
          item = _adjustment(
            id: 'approval-1',
            decision: 'approved',
            decisionReason: decisions.single['reason'] as String,
          );
          return http.Response(jsonEncode(item), 200);
        }
        return http.Response(jsonEncode([item]), 200);
      }),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: FinancialAdjustmentsView()),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        '1 awaiting a Headmaster decision. Decisions are audit records and do not post money yet.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(PrimaryButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(find.text('Approve adjustment?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pump();
    expect(
      find.text('Enter at least 3 characters for the decision reason.'),
      findsOneWidget,
    );
    expect(decisions, isEmpty);

    await tester.enterText(
      _field('Decision reason'),
      'Verified by bank ledger',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();

    expect(decisions, [
      {'decision': 'approved', 'reason': 'Verified by bank ledger'},
    ]);
    expect(find.text('Approved'), findsOneWidget);
    expect(
      find.text('Decision reason: Verified by bank ledger'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('review queue records a rejection without posting money', (
    tester,
  ) async {
    final decisions = <Map<String, dynamic>>[];
    var item = _adjustment(id: 'rejection-1');
    _installRepository(
      MockClient((request) async {
        if (request.method == 'POST') {
          decisions.add(
            (jsonDecode(request.body) as Map).cast<String, dynamic>(),
          );
          item = _adjustment(
            id: 'rejection-1',
            decision: 'rejected',
            decisionReason: decisions.single['reason'] as String,
          );
          return http.Response(jsonEncode(item), 200);
        }
        return http.Response(jsonEncode([item]), 200);
      }),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: FinancialAdjustmentsView()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reject adjustment?'), findsOneWidget);
    await tester.enterText(
      _field('Decision reason'),
      'Invoice amount is correct',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(decisions, [
      {'decision': 'rejected', 'reason': 'Invoice amount is correct'},
    ]);
    expect(find.text('Rejected'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('review queue sends filter and paging controls to the API', (
    tester,
  ) async {
    final requests = <http.Request>[];
    _installRepository(
      MockClient((request) async {
        if (request.method == 'GET') {
          requests.add(request);
          final offset =
              int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0;
          final items = offset == 0
              ? List.generate(20, (index) => _adjustment(id: 'page-$index'))
              : [_adjustment(id: 'page-$offset')];
          return http.Response(jsonEncode(items), 200);
        }
        return http.Response('{}', 404);
      }),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: FinancialAdjustmentsView()),
    );
    await tester.pumpAndSettle();
    expect(requests.single.url.queryParameters, {'limit': '20', 'offset': '0'});

    await tester.tap(find.text('All Decision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters, {
      'limit': '20',
      'offset': '0',
      'decision': 'pending',
    });

    await tester.scrollUntilVisible(find.text('Next'), 600);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters, {
      'limit': '20',
      'offset': '20',
      'decision': 'pending',
    });
    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
