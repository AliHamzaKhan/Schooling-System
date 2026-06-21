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
    T Function(dynamic json)? parser,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, query);
    final mergedHeaders = await _buildHeaders(headers, requiresAuth, isMultipart: method == HttpMethod.multipart);
    final effectiveTimeout = timeout ?? EnvConfig.apiTimeout;

    if (EnvConfig.verboseLogging) {
      developer.log('→ ${method.name.toUpperCase()} $uri', name: 'ApiService');
      if (EnvConfig.logHttpBodies && body != null) {
        developer.log('  body: $body', name: 'ApiService');
      }
    }

    try {
      late http.Response response;
      switch (method) {
        case HttpMethod.get:
          response = await _client.get(uri, headers: mergedHeaders).timeout(effectiveTimeout);
          break;
        case HttpMethod.post:
          response = await _client.post(uri, headers: mergedHeaders, body: _jsonBody(body)).timeout(effectiveTimeout);
          break;
        case HttpMethod.put:
          response = await _client.put(uri, headers: mergedHeaders, body: _jsonBody(body)).timeout(effectiveTimeout);
          break;
        case HttpMethod.patch:
          response = await _client.patch(uri, headers: mergedHeaders, body: _jsonBody(body)).timeout(effectiveTimeout);
          break;
        case HttpMethod.delete:
          response = await _client.delete(uri, headers: mergedHeaders, body: _jsonBody(body)).timeout(effectiveTimeout);
          break;
        case HttpMethod.multipart:
          response = await _sendMultipart(uri, mergedHeaders, body, files, effectiveTimeout);
          break;
      }
      final parsed = _parseResponse<T>(response, parser);
      // Session-expiry: only authenticated calls can meaningfully 401. Fire the
      // global hook so the app can log out + redirect. Login/refresh calls
      // (requiresAuth:false) are exempt so a bad-credentials 401 stays local.
      if (parsed.statusCode == 401 && requiresAuth) {
        onUnauthorized?.call();
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

  Uri _buildUri(String path, Map<String, String>? query) {
    final base = EnvConfig.apiBaseUrl.endsWith('/') ? EnvConfig.apiBaseUrl.substring(0, EnvConfig.apiBaseUrl.length - 1) : EnvConfig.apiBaseUrl;
    final full = path.startsWith('http') ? path : '$base${path.startsWith('/') ? '' : '/'}$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? extra, bool requiresAuth, {bool isMultipart = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (!isMultipart) h['Content-Type'] = 'application/json';
    if (requiresAuth) {
      final token = await _store.readToken();
      if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }

  String? _jsonBody(Map<String, dynamic>? body) => body == null ? null : jsonEncode(body);

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
