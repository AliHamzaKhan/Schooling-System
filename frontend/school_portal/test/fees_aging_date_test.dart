import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_api_service.dart';
import 'package:school_portal/school/modules/headmaster/data/headmaster_repository.dart';
import 'package:school_portal/school/modules/headmaster/features/fees/view/fees_view.dart';
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
    'aging date control is accessible, responsive, and reloads as of date',
    (tester) async {
      tester.view.physicalSize = const Size(320, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final agingRequests = <http.Request>[];
      final store = _Store();
      final api = ApiService(
        store: store,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/reports/finance')) {
            return http.Response(
              jsonEncode({
                'total_collected': 0,
                'total_billed': 100,
                'total_outstanding': 100,
                'collection_rate': 0,
                'overdue_count': 1,
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/fees/aging')) {
            agingRequests.add(request);
            return http.Response(
              jsonEncode({
                'as_of_date':
                    request.url.queryParameters['as_of'] ?? '2024-01-02',
                'buckets': [
                  {
                    'label': 'Current',
                    'invoice_count': 1,
                    'outstanding_total': 100,
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/fees/reconciliation')) {
            return http.Response(jsonEncode({'mismatch_count': 0}), 200);
          }
          return http.Response(jsonEncode([]), 200);
        }),
      );
      final auth = AuthService(api: api, store: store);
      auth.currentUser.value = {'id': 'headmaster', 'school_id': 'school'};
      Get.put<AuthService>(auth);
      Get.put<HeadmasterRepository>(
        HeadmasterRepository(api: HeadmasterApiService(api: api)),
      );
      final repository = Get.find<HeadmasterRepository>();
      final result = await repository.loadFees(
        agingAsOf: DateTime(2023, 12, 31),
      );
      expect(result.success, isTrue);
      expect(result.data?.agingAsOfDate, DateTime(2023, 12, 31));
      expect(agingRequests, hasLength(1));
      expect(agingRequests.single.url.queryParameters['as_of'], '2023-12-31');

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 200),
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: AgingHeader(
                asOf: result.data!.agingAsOfDate,
                onSelectDate: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('As of'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label ?? '').startsWith(
                'Select aging report date. Current date:',
              ),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(OutlinedButton)).width, 320);
      expect(tester.takeException(), isNull);
    },
  );
}
