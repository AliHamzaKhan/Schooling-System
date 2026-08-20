/// Standard wrapper for every [ApiService.request] call.
///
/// `success` is true for 2xx, false for 4xx/5xx. `data` is the parsed body
/// (via the optional `parser` callback) or the raw decoded JSON. `error`
/// holds a human-readable message when `success` is false.
class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final T? data;
  final String? error;

  /// Machine-readable failure identifier from the backend envelope
  /// `{error: {code}}` (e.g. `subscription_inactive`, `tenant_disabled`), or
  /// null for successes and pre-envelope error shapes. Prefer this over
  /// [statusCode] when deciding how to react — two different failures can share
  /// a status (a permission denial and a disabled tenant are both 403).
  final String? errorCode;

  /// The unwrapped `data` object from the backend envelope `{data, meta}`.
  /// (For object endpoints this is the inner map; null for list payloads.)
  final Map<String, dynamic>? rawJson;

  /// Pagination / extra info from the envelope `meta` block, if present.
  final Map<String, dynamic>? meta;

  /// Field-level validation errors `{field: message}` from `{error: {fields}}`.
  final Map<String, dynamic>? fieldErrors;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
    this.errorCode,
    this.rawJson,
    this.meta,
    this.fieldErrors,
  });

  factory ApiResponse.ok(T data, {int statusCode = 200, Map<String, dynamic>? rawJson}) =>
      ApiResponse(success: true, statusCode: statusCode, data: data, rawJson: rawJson);

  factory ApiResponse.fail(String error, {int statusCode = 500, Map<String, dynamic>? rawJson}) =>
      ApiResponse(success: false, statusCode: statusCode, error: error, rawJson: rawJson);

  /// Backend error codes that invalidate the whole session: the tenant/account
  /// is gone or disabled, the subscription lapsed, or credentials are no longer
  /// valid. Kept in sync with `ErrorCode` in `backend/app/core/exceptions.py`.
  static const Set<String> sessionFatalCodes = {
    'invalid_credentials',
    'account_inactive',
    'tenant_mismatch',
    'tenant_not_found',
    'tenant_disabled',
    'subscription_inactive',
  };

  /// True when the request never reached the server (offline, server down,
  /// timeout, or a response the browser refused). [statusCode] is 0 because
  /// there was no HTTP response at all.
  bool get isNetworkError => statusCode == 0;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isPaymentRequired => statusCode == 402;
  bool get isServerError => statusCode >= 500;

  /// Whether this failure means the session can no longer be trusted and the
  /// user must be returned to login. True when the backend sent a session-fatal
  /// [errorCode], and — as a defensive fallback for any endpoint not yet on the
  /// enveloped error format — for a bare 401 (auth) or 402 (subscription).
  /// A plain 403 permission denial is deliberately excluded: it means "not
  /// allowed here", not "your session is invalid".
  bool get isSessionFatal =>
      (errorCode != null && sessionFatalCodes.contains(errorCode)) ||
      isUnauthorized ||
      isPaymentRequired;
}
