import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_response.dart';

/// One immutable broadcast per actor/school while its save outcome is unknown.
/// Deliberately in-memory: not an offline queue or delivery retry mechanism.
class BroadcastRetryGuard {
  final _pending = <String, _Attempt>{};
  final _running = <String, Future<ApiResponse<dynamic>>>{};

  Map<String, dynamic>? pending(String scope) => _pending[scope]?.payload;

  Future<ApiResponse<dynamic>> run({
    required String scope,
    required Map<String, dynamic> payload,
    required Future<ApiResponse<dynamic>> Function(String, Map<String, dynamic>)
    send,
  }) {
    final previous = _pending[scope];
    // Broadcast payloads contain only scalar fields. Never silently send an
    // older message when the user has changed the visible composer.
    if (previous != null && !mapEquals(previous.payload, payload)) {
      return Future.value(
        ApiResponse.fail(
          'The previous save is unresolved. Reopen the composer to restore it, '
          'then retry unchanged before creating another announcement.',
          statusCode: 409,
        ),
      );
    }
    final running = _running[scope];
    if (running != null) return running;
    final attempt = _pending.putIfAbsent(
      scope,
      () => _Attempt(_key(), Map.unmodifiable(payload)),
    );
    final future = _send(scope, attempt, send);
    _running[scope] = future;
    return future;
  }

  Future<ApiResponse<dynamic>> _send(
    String scope,
    _Attempt attempt,
    Future<ApiResponse<dynamic>> Function(String, Map<String, dynamic>) send,
  ) async {
    try {
      final result = await Future<ApiResponse<dynamic>>.sync(
        () => send(attempt.key, attempt.payload),
      );
      if (result.success ||
          result.statusCode == 400 ||
          result.statusCode == 422) {
        _pending.remove(scope);
      }
      return result;
    } catch (_) {
      return ApiResponse.fail(
        'Save outcome is unknown. Retry this announcement unchanged.',
        statusCode: 0,
      );
    } finally {
      _running.remove(scope);
    }
  }

  static String _key() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class _Attempt {
  final String key;
  final Map<String, dynamic> payload;
  _Attempt(this.key, this.payload);
}
