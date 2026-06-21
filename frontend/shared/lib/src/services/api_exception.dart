/// Thrown by [ApiService] when an HTTP call fails in an unexpected way.
///
/// Expected 4xx/5xx responses are NOT thrown — they come back as
/// `ApiResponse(success: false, statusCode: 4xx, error: ...)` so the caller
/// can branch without try/catch. This exception is reserved for network
/// failures, timeouts, JSON decode errors, and similar low-level problems.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic cause;

  ApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
