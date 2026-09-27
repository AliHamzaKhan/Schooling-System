import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/salary/controller/salary_controller.dart';
import 'package:school_portal/school/modules/headmaster/features/salary/view/salary_view.dart';
import 'package:shared/shared.dart';

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

  testWidgets(
    'submits a non-posting payroll correction request for its payslip',
    (tester) async {
      http.Request? adjustmentRequest;
      final api = ApiService(
        store: _Store(),
        client: MockClient((request) async {
          if (request.method == 'GET' && request.url.path.endsWith('/users')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'teacher-1',
                  'full_name': 'Ayesha Khan',
                  'email': 'ayesha@example.test',
                },
              ]),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/hr/staff')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'profile-1',
                  'user_id': 'teacher-1',
                  'designation': 'Teacher',
                  'base_salary': 60000,
                },
              ]),
              200,
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/hr/payslips')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 'payslip-1',
                  'staff_profile_id': 'profile-1',
                  'period_month': 9,
                  'period_year': 2026,
                  'gross': 60000,
                  'net': 60000,
                  'status': 'pending',
                },
              ]),
              200,
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/fees/adjustments')) {
            adjustmentRequest = request;
            return http.Response(jsonEncode({'id': 'adjustment-1'}), 201);
          }
          return http.Response('not found', 404);
        }),
      );
      final auth = AuthService(api: api, store: _Store());
      auth.currentUser.value = {'id': 'headmaster', 'school_id': 'school'};
      Get.put<AuthService>(auth);
      final repository = HeadmasterRepository(
        api: HeadmasterApiService(api: api),
      );
      Get.put<HeadmasterRepository>(repository);
      Get.put<SalaryController>(SalaryController(repo: repository));

      await tester.pumpWidget(const GetMaterialApp(home: SalaryView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correction'));
      await tester.pumpAndSettle();
      expect(find.text('Request Payroll Correction'), findsOneWidget);
      expect(
        find.textContaining('This creates a review request only.'),
        findsOneWidget,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1500.00');
      await tester.enterText(fields.at(1), 'pkr');
      await tester.enterText(fields.at(2), 'Correct attendance deduction');
      final submit = find.text('Submit for review');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(adjustmentRequest, isNotNull);
      expect(
        adjustmentRequest!.url.path,
        '/api/v1/schools/school/fees/adjustments',
      );
      expect(jsonDecode(adjustmentRequest!.body), {
        'kind': 'payroll_correction',
        'target_id': 'payslip-1',
        'proposed_amount': '1500.00',
        'currency_code': 'PKR',
        'reason': 'Correct attendance deduction',
      });
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );
}
