import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env/env_config.dart';
import 'api_response.dart';
import 'data_store_service.dart';
import 'http_method.dart';

/// A refresh outage is recoverable, not evidence that credentials were revoked.
class SessionRefreshUnavailable implements Exception {}

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
  final void Function(String)? _diagnosticWriter;

  /// Optional global hook fired whenever an **authenticated** request comes back
  /// with a session-fatal failure — a still-401 after a refresh attempt (token
  /// expired / revoked), or a tenant/subscription failure the backend flagged
  /// via [ApiResponse.isSessionFatal] (disabled tenant, lapsed subscription,
  /// deactivated account, cross-tenant access). Wire this once at boot to clear
  /// the session and route to login. Kept as a plain callback so `shared` stays
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
  int _sessionGeneration = 0;

  /// Stop requests from an earlier login/logout boundary from being replayed.
  void invalidateSessionRequests() => _sessionGeneration++;

  ApiService({
    http.Client? client,
    required DataStoreService store,
    void Function(String)? diagnosticWriter,
  }) : _client = client ?? http.Client(),
       _store = store,
       _diagnosticWriter = diagnosticWriter;

  void _diagnostic(String message) {
    if (!EnvConfig.verboseLogging) return;
    if (_diagnosticWriter != null) {
      _diagnosticWriter(message);
    } else {
      developer.log(message, name: 'ApiService');
    }
  }

  /// Single entry point for every HTTP call. Never throws: HTTP 4xx/5xx *and*
  /// network-level failures (server down, DNS, timeout, CORS-blocked response)
  /// all come back as `ApiResponse.fail(...)`, the latter with
  /// [ApiResponse.isNetworkError] set. Screens already branch on
  /// `res.success`, so a backend outage shows the error state instead of
  /// escaping as an unhandled `ApiException` that takes the screen down.
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
    final sessionGeneration = _sessionGeneration;
    final uri = _buildUri(path, query);
    final mergedHeaders = await _buildHeaders(
      headers,
      requiresAuth,
      isMultipart: method == HttpMethod.multipart,
      asForm: asForm,
    );
    final effectiveTimeout = timeout ?? EnvConfig.apiTimeout;

    // Never log URLs, payloads or headers: any can contain credentials or PII.
    _diagnostic('→ ${method.name.toUpperCase()}');

    try {
      var headersToUse = mergedHeaders;
      var response = await _dispatch(
        method,
        uri,
        headersToUse,
        body,
        files,
        asForm,
        effectiveTimeout,
      );
      var parsed = _parseResponse<T>(response, parser);

      if (requiresAuth && sessionGeneration != _sessionGeneration) {
        return ApiResponse.fail(
          'Session changed. Please retry.',
          statusCode: 401,
        );
      }

      // Session-expiry: only authenticated calls can meaningfully 401. Try a
      // one-time token refresh + retry before giving up; login/refresh calls
      // (requiresAuth:false) are exempt so a bad-credentials 401 stays local.
      if (parsed.statusCode == 401 && requiresAuth) {
        if (tokenRefresher != null && await _refreshToken()) {
          if (sessionGeneration != _sessionGeneration) {
            return ApiResponse.fail(
              'Session changed. Please retry.',
              statusCode: 401,
            );
          }
          headersToUse = await _buildHeaders(
            headers,
            requiresAuth,
            isMultipart: method == HttpMethod.multipart,
            asForm: asForm,
          );
          if (sessionGeneration != _sessionGeneration) {
            return ApiResponse.fail(
              'Session changed. Please retry.',
              statusCode: 401,
            );
          }
          response = await _dispatch(
            method,
            uri,
            headersToUse,
            body,
            files,
            asForm,
            effectiveTimeout,
          );
          parsed = _parseResponse<T>(response, parser);
        }
      }

      if (requiresAuth && sessionGeneration != _sessionGeneration) {
        return ApiResponse.fail(
          'Session changed. Please retry.',
          statusCode: 401,
        );
      }

      // Any session-fatal failure on an authenticated call clears the session
      // and routes to login: a still-401 after the refresh attempt above, plus
      // the tenant/subscription/account failures the backend flags with an
      // `error.code` (disabled tenant, expired subscription, deactivated
      // account, cross-tenant access). A token refresh can't rescue those, so
      // they don't go through the retry path. Unauthenticated calls
      // (login/refresh) are exempt so a bad-credentials attempt stays local.
      if (requiresAuth && parsed.isSessionFatal) {
        final activeToken = await _store.readToken();
        // A late denial from a previous login must not log out a newer account.
        if (sessionGeneration == _sessionGeneration &&
            activeToken != null &&
            headersToUse['Authorization'] == 'Bearer $activeToken') {
          onUnauthorized?.call();
        }
      }
      return parsed;
    } on SessionRefreshUnavailable {
      return ApiResponse.fail(
        'Could not renew the session. Check your connection and retry.',
        statusCode: 0,
      );
    } on TimeoutException {
      return _transportFailure(
        uri,
        'The server took too long to respond (${effectiveTimeout.inSeconds}s). Please try again.',
      );
    } on SocketException catch (e) {
      return _transportFailure(
        uri,
        'Cannot reach the server. Check your connection and try again.',
        e,
      );
    } on http.ClientException catch (e) {
      // Includes the browser's opaque "Failed to fetch" — server down, wrong
      // host, or a response the browser rejected (e.g. a 500 with no CORS
      // headers). All of them mean "the request never completed".
      return _transportFailure(
        uri,
        'Cannot reach the server. Check your connection and try again.',
        e,
      );
    } on FormatException catch (e) {
      return _transportFailure(
        uri,
        'The server sent a response the app could not read.',
        e,
      );
    } catch (e) {
      // Last-resort net: an unexpected transport error must not surface as an
      // unhandled exception in the widget tree.
      return _transportFailure(
        uri,
        'Something went wrong talking to the server.',
        e,
      );
    }
  }

  /// Builds the failed response for a request that never completed, and logs
  /// only the error category. Exception text can contain URLs and payloads.
  ApiResponse<T> _transportFailure<T>(
    Uri uri,
    String message, [
    Object? cause,
  ]) {
    _diagnostic('✗ ${cause?.runtimeType ?? 'Timeout'}');
    return ApiResponse<T>.fail(message, statusCode: 0);
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
        return _client
            .post(uri, headers: headers, body: _encodeBody(body, asForm))
            .timeout(timeout);
      case HttpMethod.put:
        return _client
            .put(uri, headers: headers, body: _encodeBody(body, asForm))
            .timeout(timeout);
      case HttpMethod.patch:
        return _client
            .patch(uri, headers: headers, body: _encodeBody(body, asForm))
            .timeout(timeout);
      case HttpMethod.delete:
        return _client
            .delete(uri, headers: headers, body: _encodeBody(body, asForm))
            .timeout(timeout);
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
    final base = EnvConfig.apiBaseUrl.endsWith('/')
        ? EnvConfig.apiBaseUrl.substring(0, EnvConfig.apiBaseUrl.length - 1)
        : EnvConfig.apiBaseUrl;
    final full = path.startsWith('http')
        ? path
        : '$base${path.startsWith('/') ? '' : '/'}$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? extra,
    bool requiresAuth, {
    bool isMultipart = false,
    bool asForm = false,
  }) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (!isMultipart) {
      h['Content-Type'] = asForm
          ? 'application/x-www-form-urlencoded'
          : 'application/json';
    }
    if (requiresAuth) {
      final token = await _store.readToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
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
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value?.toString() ?? '')}',
        )
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
          req.files.add(
            await http.MultipartFile.fromPath(
              f.field,
              f.file!.path,
              filename: f.filename,
            ),
          );
        } else if (f.bytes != null) {
          req.files.add(
            http.MultipartFile.fromBytes(
              f.field,
              f.bytes!,
              filename: f.filename,
            ),
          );
        }
      }
    }
    final streamed = await req.send().timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response res,
    T Function(dynamic json)? parser,
  ) {
    final status = res.statusCode;
    dynamic decoded;
    try {
      decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    _diagnostic('← $status (${res.body.length} bytes)');

    final isOk = status >= 200 && status < 300;
    if (!isOk) {
      return ApiResponse<T>(
        success: false,
        statusCode: status,
        error: _extractError(decoded) ?? 'HTTP $status',
        errorCode: _extractErrorCode(decoded),
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

  /// The machine-readable `error.code` from the backend envelope
  /// `{error: {code, message}}`, or null for pre-envelope error shapes.
  String? _extractErrorCode(dynamic decoded) {
    if (decoded is Map) {
      final err = decoded['error'];
      if (err is Map && err['code'] is String) return err['code'] as String;
    }
    return null;
  }

  String? _extractError(dynamic decoded) {
    if (decoded is Map) {
      // Standard envelope: { "error": { "code", "message", "fields"? } }.
      final err = decoded['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
      if (err is String) return err;
      // Fallbacks for FastAPI default / other shapes.
      final detail = decoded['detail'] ?? decoded['message'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail
            .map((e) => e is Map ? e['msg'] ?? e.toString() : e.toString())
            .join(' · ');
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
