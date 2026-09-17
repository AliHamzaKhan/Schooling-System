import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  test('coalesces overlapping taps into one immutable request', () async {
    final guard = PaymentRetryGuard();
    final completed = Completer<ApiResponse<dynamic>>();
    var sends = 0;
    Future<ApiResponse<dynamic>> run() => guard.run(
      scope: 'user/school/invoice',
      createPayload: () => {'amount': 30, 'paid_on': '2026-09-14'},
      send: (key, payload) {
        sends++;
        expect(
          key,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(() => payload['amount'] = 99, throwsUnsupportedError);
        return completed.future;
      },
    );
    final first = run();
    final second = run();
    expect(identical(first, second), isTrue);
    expect(sends, 1);
    completed.complete(ApiResponse.ok({'id': 'payment'}));
    expect((await first).success, isTrue);
    expect((await second).success, isTrue);
  });

  for (final code in [0, 500, 503, 401, 409]) {
    test(
      'uncertain/error $code retains key, amount and original payment date',
      () async {
        final guard = PaymentRetryGuard();
        final keys = <String>[];
        final bodies = <Map<String, dynamic>>[];
        for (var attempt = 0; attempt < 2; attempt++) {
          await guard.run(
            scope: 'user/school/invoice',
            createPayload: () => {
              'amount': attempt == 0 ? 30 : 70,
              'paid_on': attempt == 0 ? '2026-09-14' : '2026-09-15',
            },
            send: (key, body) async {
              keys.add(key);
              bodies.add(body);
              return attempt == 0
                  ? ApiResponse.fail('uncertain', statusCode: code)
                  : ApiResponse.ok({});
            },
          );
        }
        expect(keys[0], keys[1]);
        expect(bodies[0], bodies[1]);
        expect(bodies[1]['amount'], 30);
        expect(bodies[1]['paid_on'], '2026-09-14');
      },
    );
  }

  for (final code in [200, 400, 422]) {
    test(
      'success or definite validation rejection $code permits a fresh intent',
      () async {
        final guard = PaymentRetryGuard();
        final keys = <String>[];
        for (var attempt = 0; attempt < 2; attempt++) {
          await guard.run(
            scope: 'scope',
            createPayload: () => {'amount': 30},
            send: (key, _) async {
              keys.add(key);
              return code == 200
                  ? ApiResponse.ok({})
                  : ApiResponse.fail('validation', statusCode: code);
            },
          );
        }
        expect(keys[0], isNot(keys[1]));
      },
    );
  }

  test(
    'synchronous exception retains retry identity without a stuck in-flight entry',
    () async {
      final guard = PaymentRetryGuard();
      String? key;
      final failed = await guard.run(
        scope: 'scope',
        createPayload: () => {'amount': 30},
        send: (value, _) {
          key = value;
          throw StateError('sensitive exception');
        },
      );
      expect(failed.isNetworkError, isTrue);
      expect(failed.error, isNot(contains('sensitive')));
      var sends = 0;
      await guard.run(
        scope: 'scope',
        createPayload: () => {},
        send: (value, _) async {
          sends++;
          expect(value, key);
          return ApiResponse.ok({});
        },
      );
      expect(sends, 1);
    },
  );

  test('pending attempts are separated by actor, tenant and invoice', () async {
    final guard = PaymentRetryGuard();
    final keys = <String>{};
    for (final scope in ['u1/s1/i1', 'u2/s1/i1', 'u1/s2/i1', 'u1/s1/i2']) {
      await guard.run(
        scope: scope,
        createPayload: () => {},
        send: (key, _) async {
          keys.add(key);
          return ApiResponse.fail('offline', statusCode: 0);
        },
      );
    }
    expect(keys.length, 4);
  });
}
