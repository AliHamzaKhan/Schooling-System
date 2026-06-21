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
    this.rawJson,
    this.meta,
    this.fieldErrors,
  });

  factory ApiResponse.ok(T data, {int statusCode = 200, Map<String, dynamic>? rawJson}) =>
      ApiResponse(success: true, statusCode: statusCode, data: data, rawJson: rawJson);

  factory ApiResponse.fail(String error, {int statusCode = 500, Map<String, dynamic>? rawJson}) =>
      ApiResponse(success: false, statusCode: statusCode, error: error, rawJson: rawJson);

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}
