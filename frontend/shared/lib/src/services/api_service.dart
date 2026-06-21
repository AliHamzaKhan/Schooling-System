import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env/env_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'data_store_service.dart';
import 'http_method.dart';

/// Multipart file payload — wraps either a [File] from disk or in-memory bytes.
class MultipartUpload {
  final String field;
  final String filename;
  final List<int>? bytes;
  final File? file;
  final String? contentType; // e.g. 'image/jpeg'

  const MultipartUpload({
    required this.field,
    required this.filename,
    this.bytes,
    this.file,
    this.contentType,
  }) : assert(bytes != null || file != null, 'Provide either bytes or file');
}

/// Single-entry HTTP gateway for the whole app.
///
/// All requests funnel through [request] — the [HttpMethod] enum decides how
/// the body / multipart fields are dispatched. Auth header is injected from
/// [DataStoreService.readToken] when `requiresAuth` is true.
///
/// Usage:
/// ```dart
/// final api = Get.find<ApiService>();
/// final res = await api.request<Map<String, dynamic>>(
///   method: HttpMethod.post,
///   path: '/auth/login',
///   body: {'email': 'x@y.z', 'password': '...'},
///   requiresAuth: false,
/// );
/// if (res.success) { ... }
/// ```
class ApiService {
  final http.Client _client;
  final DataStoreService _store;

  /// Optional global hook fired whenever an **authenticated** request returns
  /// HTTP 401 (token expired / revoked). Wire this once at boot to clear the
  /// session and route to login. Kept as a plain callback so `shared` stays
  /// free of any app-level routing/auth dependency.
  void Function()? onUnauthorized;

  /// Optional async hook to refresh the access token after a 401 on an
  /// authenticated request. Should return true when a fresh token was stored,
  /// in which case the original request is retried once before [onUnauthorized]
  /// is fired. Wire to `AuthService.refreshSession` at boot. Kept as a plain
  /// callback so `shared` stays free of app-level auth wiring.
  Future<bool> Function()? tokenRefresher;

  /// Coalesces concurrent refreshes so several parallel 401s share one refresh.
  Future<bool>? _refreshInFlight;

  ApiService({http.Client? client, required DataStoreService store})
      : _client = client ?? http.Client(),
        _store = store;

  /// Single entry point for every HTTP call. Throws [ApiException] only for
  /// network-level failures; HTTP 4xx/5xx come back as
  /// `ApiResponse.fail(...)`.
  Future<ApiResponse<T>> request<T>({
    required HttpMethod method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    List<MultipartUpload>? files,
    bool requiresAuth = true,
    bool asForm = false,
    T Function(dynamic json)? parser,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, query);
    final mergedHeaders = await _buildHeaders(headers, requiresAuth,
        isMultipart: method == HttpMethod.multipart, asForm: asForm);
    final effectiveTimeout = timeout ?? EnvConfig.apiTimeout;

    if (EnvConfig.verboseLogging) {
      developer.log('→ ${method.name.toUpperCase()} $uri', name: 'ApiService');
      if (EnvConfig.logHttpBodies && body != null) {
        developer.log('  body: $body', name: 'ApiService');
      }
    }

    try {
      var headersToUse = mergedHeaders;
      var response = await _dispatch(
          method, uri, headersToUse, body, files, asForm, effectiveTimeout);
      var parsed = _parseResponse<T>(response, parser);

      // Session-expiry: only authenticated calls can meaningfully 401. Try a
      // one-time token refresh + retry before giving up; login/refresh calls
      // (requiresAuth:false) are exempt so a bad-credentials 401 stays local.
      if (parsed.statusCode == 401 && requiresAuth) {
        if (tokenRefresher != null && await _refreshToken()) {
          headersToUse = await _buildHeaders(headers, requiresAuth,
              isMultipart: method == HttpMethod.multipart, asForm: asForm);
          response = await _dispatch(
              method, uri, headersToUse, body, files, asForm, effectiveTimeout);
          parsed = _parseResponse<T>(response, parser);
        }
        // Still unauthorized after a refresh attempt → clear session/redirect.
        if (parsed.statusCode == 401) onUnauthorized?.call();
      }
      return parsed;
    } on TimeoutException {
      throw ApiException('Request timed out after ${effectiveTimeout.inSeconds}s', cause: 'timeout');
    } on SocketException catch (e) {
      throw ApiException('Network unreachable: ${e.message}', cause: e);
    } on http.ClientException catch (e) {
      throw ApiException('HTTP client error: ${e.message}', cause: e);
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}', cause: e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  /// Sends one HTTP request for [method]. Extracted so a request can be
  /// re-dispatched after a token refresh without duplicating the verb switch.
  Future<http.Response> _dispatch(
    HttpMethod method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
    List<MultipartUpload>? files,
    bool asForm,
    Duration timeout,
  ) {
    switch (method) {
      case HttpMethod.get:
        return _client.get(uri, headers: headers).timeout(timeout);
      case HttpMethod.post:
        return _client.post(uri, headers: headers, body: _encodeBody(body, asForm)).timeout(timeout);
      case HttpMethod.put:
        return _client.put(uri, headers: headers, body: _encodeBody(body, asForm)).timeout(timeout);
      case HttpMethod.patch:
        return _client.patch(uri, headers: headers, body: _encodeBody(body, asForm)).timeout(timeout);
      case HttpMethod.delete:
        return _client.delete(uri, headers: headers, body: _encodeBody(body, asForm)).timeout(timeout);
      case HttpMethod.multipart:
        return _sendMultipart(uri, headers, body, files, timeout);
    }
  }

  /// Runs [tokenRefresher] at most once concurrently; parallel 401s await the
  /// same refresh instead of each firing their own.
  Future<bool> _refreshToken() {
    return _refreshInFlight ??= () async {
      try {
        return await tokenRefresher?.call() ?? false;
      } finally {
        _refreshInFlight = null;
      }
    }();
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = EnvConfig.apiBaseUrl.endsWith('/') ? EnvConfig.apiBaseUrl.substring(0, EnvConfig.apiBaseUrl.length - 1) : EnvConfig.apiBaseUrl;
    final full = path.startsWith('http') ? path : '$base${path.startsWith('/') ? '' : '/'}$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? extra, bool requiresAuth, {bool isMultipart = false, bool asForm = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (!isMultipart) {
      h['Content-Type'] =
          asForm ? 'application/x-www-form-urlencoded' : 'application/json';
    }
    if (requiresAuth) {
      final token = await _store.readToken();
      if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }

  /// Encodes the request body as JSON (default) or as
  /// `application/x-www-form-urlencoded` when [asForm] is true (e.g. OAuth2
  /// password login). Returns null when there is no body.
  String? _encodeBody(Map<String, dynamic>? body, bool asForm) {
    if (body == null) return null;
    if (!asForm) return jsonEncode(body);
    return body.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value?.toString() ?? '')}')
        .join('&');
  }

  Future<http.Response> _sendMultipart(
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? fields,
    List<MultipartUpload>? files,
    Duration timeout,
  ) async {
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(headers);
    if (fields != null) {
      fields.forEach((k, v) => req.fields[k] = v.toString());
    }
    if (files != null) {
      for (final f in files) {
        if (f.file != null) {
          req.files.add(await http.MultipartFile.fromPath(f.field, f.file!.path, filename: f.filename));
        } else if (f.bytes != null) {
          req.files.add(http.MultipartFile.fromBytes(f.field, f.bytes!, filename: f.filename));
        }
      }
    }
    final streamed = await req.send().timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  ApiResponse<T> _parseResponse<T>(http.Response res, T Function(dynamic json)? parser) {
    final status = res.statusCode;
    dynamic decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    if (EnvConfig.verboseLogging) {
      developer.log('← $status (${res.body.length} bytes)', name: 'ApiService');
    }

    final isOk = status >= 200 && status < 300;
    if (!isOk) {
      return ApiResponse<T>(
        success: false,
        statusCode: status,
        error: _extractError(decoded) ?? 'HTTP $status',
        fieldErrors: _extractFieldErrors(decoded),
        rawJson: decoded is Map<String, dynamic> ? decoded : null,
      );
    }

    // Unwrap the standard backend envelope: { "data": ..., "meta"?: {...} }.
    dynamic payload = decoded;
    Map<String, dynamic>? meta;
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      payload = decoded['data'];
      final m = decoded['meta'];
      if (m is Map<String, dynamic>) meta = m;
    }

    T? data;
    if (parser != null && payload != null) {
      data = parser(payload);
    } else if (payload is T) {
      data = payload;
    } else {
      data = payload as T?;
    }

    return ApiResponse<T>(
      success: true,
      statusCode: status,
      data: data,
      meta: meta,
      rawJson: payload is Map<String, dynamic> ? payload : null,
    );
  }

  String? _extractError(dynamic decoded) {
    if (decoded is Map) {
      // Standard envelope: { "error": { "code", "message", "fields"? } }.
      final err = decoded['error'];
      if (err is Map && err['message'] is String) return err['message'] as String;
      if (err is String) return err;
      // Fallbacks for FastAPI default / other shapes.
      final detail = decoded['detail'] ?? decoded['message'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString()).join(' · ');
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractFieldErrors(dynamic decoded) {
    if (decoded is Map) {
      final err = decoded['error'];
      if (err is Map && err['fields'] is Map) {
        return Map<String, dynamic>.from(err['fields'] as Map);
      }
    }
    return null;
  }

  void dispose() => _client.close();
}
