import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const payload = {'body': 'School update', 'channel': 'push'};

  test('overlapping submissions share a key and one HTTP attempt', () async {
    final guard = BroadcastRetryGuard();
    final result = Completer<ApiResponse<dynamic>>();
    var calls = 0;
    Future<ApiResponse<dynamic>> send(String key, Map<String, dynamic> body) {
      calls++;
      expect(
        key,
        matches(
          RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ),
        ),
      );
      expect(() => body['body'] = 'mutation', throwsUnsupportedError);
      return result.future;
    }

    final first = guard.run(scope: 'user/school', payload: payload, send: send);
    final second = guard.run(
      scope: 'user/school',
      payload: payload,
      send: send,
    );
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    result.complete(ApiResponse.ok({'id': 'message'}));
    await first;
    expect(guard.pending('user/school'), isNull);
  });

  for (final status in [0, 401, 403, 409, 500, 503]) {
    test('uncertain $status preserves original content and identity', () async {
      final guard = BroadcastRetryGuard();
      final keys = <String>[];
      Future<ApiResponse<dynamic>> send(
        String key,
        Map<String, dynamic> body,
      ) async {
        keys.add(key);
        return ApiResponse.fail('Unresolved', statusCode: status);
      }

      await guard.run(scope: 'user/school', payload: payload, send: send);
      final conflict = await guard.run(
        scope: 'user/school',
        payload: {'body': 'Changed'},
        send: send,
      );
      expect(conflict.statusCode, 409);
      expect(keys, hasLength(1));
      expect(guard.pending('user/school'), payload);
      await guard.run(scope: 'user/school', payload: payload, send: send);
      expect(keys[0], keys[1]);
      await guard.run(scope: 'other/school', payload: payload, send: send);
      await guard.run(scope: 'user/other-school', payload: payload, send: send);
      expect(keys.toSet(), hasLength(3));
    });
  }

  for (final status in [201, 400, 422]) {
    test('known $status outcome releases the next composition', () async {
      final guard = BroadcastRetryGuard();
      final keys = <String>[];
      Future<ApiResponse<dynamic>> send(
        String key,
        Map<String, dynamic> body,
      ) async {
        keys.add(key);
        return status == 201
            ? ApiResponse.ok({})
            : ApiResponse.fail('Rejected', statusCode: status);
      }

      await guard.run(scope: 'scope', payload: payload, send: send);
      await guard.run(scope: 'scope', payload: payload, send: send);
      expect(keys.toSet(), hasLength(2));
    });
  }

  test('transport exception retains a recoverable immutable draft', () async {
    final guard = BroadcastRetryGuard();
    final result = await guard.run(
      scope: 'scope',
      payload: payload,
      send: (_, _) => throw StateError('network'),
    );
    expect(result.statusCode, 0);
    expect(guard.pending('scope'), payload);
  });
}
