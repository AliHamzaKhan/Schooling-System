import 'dart:math';

import 'api_response.dart';

/// One immutable in-memory attempt per user/school/invoice. An uncertain
/// response must be retried, not converted into a new payment with a new key.
/// This is not a persisted offline queue or cross-device reconciliation store.
class PaymentRetryGuard {
  final _pending = <String, _PaymentAttempt>{};
  final _inFlight = <String, Future<ApiResponse<dynamic>>>{};

  Future<ApiResponse<dynamic>> run({
    required String scope,
    required Map<String, dynamic> Function() createPayload,
    required Future<ApiResponse<dynamic>> Function(
      String key,
      Map<String, dynamic> payload,
    )
    send,
  }) {
    final running = _inFlight[scope];
    if (running != null) return running;
    final attempt = _pending.putIfAbsent(
      scope,
      () => _PaymentAttempt(_newKey(), Map.unmodifiable(createPayload())),
    );
    final future = _send(scope, attempt, send);
    _inFlight[scope] = future;
    return future;
  }

  Future<ApiResponse<dynamic>> _send(
    String scope,
    _PaymentAttempt attempt,
    Future<ApiResponse<dynamic>> Function(String, Map<String, dynamic>) send,
  ) async {
    try {
      final result = await Future<ApiResponse<dynamic>>.sync(
        () => send(attempt.key, attempt.payload),
      );
      // Validated 400/422 denials do not commit payments. Unknown outcomes,
      // conflicts and auth failures retain the identity until reconciled.
      if (result.success ||
          result.statusCode == 400 ||
          result.statusCode == 422) {
        _pending.remove(scope);
      }
      return result;
    } catch (_) {
      return ApiResponse.fail(
        'Payment outcome is unknown. Retry the same request.',
        statusCode: 0,
      );
    } finally {
      _inFlight.remove(scope);
    }
  }

  static String _newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class _PaymentAttempt {
  final String key;
  final Map<String, dynamic> payload;
  _PaymentAttempt(this.key, this.payload);
}
