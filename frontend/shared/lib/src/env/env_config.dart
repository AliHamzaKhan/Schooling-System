import 'package:flutter/foundation.dart' show kReleaseMode;

import 'environment.dart';

/// Central, environment-aware configuration read by the shared services
/// ([ApiService], ads, notifications). Call [bootstrap] exactly once during app
/// startup — before `runApp`. Builds select the environment through `APP_ENV`.
///
/// Every value can be overridden at build time with `--dart-define`, so a
/// physical device or CI job can point at a different backend without a code
/// change, e.g.:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api/v1
/// ```
class EnvConfig {
  EnvConfig._();

  static Environment _current = kReleaseMode
      ? Environment.prod
      : Environment.debug;

  /// Release builds default to production; development builds default to debug.
  static Environment get current => _current;

  /// Select the runtime [Environment]. Call once, before `runApp`.
  static void bootstrap([Environment? env]) {
    final selected =
        env ??
        resolveEnvironment(
          const String.fromEnvironment('APP_ENV'),
          release: kReleaseMode,
        );
    if (kReleaseMode && selected == Environment.debug) {
      throw StateError('Release builds cannot use the debug environment.');
    }
    // Validate before publishing configuration or starting network services.
    validateApiUrl(_baseUrlFor(selected), selected);
    _current = selected;
  }

  static Environment resolveEnvironment(String value, {required bool release}) {
    final selected = switch (value.trim().toLowerCase()) {
      '' => release ? Environment.prod : Environment.debug,
      'debug' || 'development' => Environment.debug,
      'staging' => Environment.staging,
      'prod' || 'production' => Environment.prod,
      _ => throw StateError(
        'APP_ENV must be development, staging or production.',
      ),
    };
    if (release && selected == Environment.debug) {
      throw StateError('Release builds cannot use the debug environment.');
    }
    return selected;
  }

  static void validateApiUrl(String raw, Environment env) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !RegExp(r'/api/v\d+/?$').hasMatch(uri.path)) {
      throw StateError(
        'API_BASE_URL must be an HTTP(S) API URL without credentials, query or fragment.',
      );
    }
    if (env != Environment.debug) {
      final host = uri.host.toLowerCase();
      final octets = host.split('.').map(int.tryParse).toList();
      final privateIpv4 =
          octets.length == 4 &&
          octets.every((part) => part != null) &&
          (octets[0] == 0 ||
              octets[0] == 10 ||
              octets[0] == 127 ||
              (octets[0] == 169 && octets[1] == 254) ||
              (octets[0] == 192 && octets[1] == 168) ||
              (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31));
      // Public DNS name required for distributed staging/production builds.
      if (uri.scheme != 'https' ||
          privateIpv4 ||
          host.contains(':') ||
          RegExp(r'^[0-9.]+$').hasMatch(host) ||
          !host.contains('.') ||
          host == 'localhost' ||
          host.endsWith('.localhost') ||
          host.endsWith('.local') ||
          host.endsWith('.internal')) {
        throw StateError(
          'Staging/production API_BASE_URL must use HTTPS and a public host.',
        );
      }
    }
  }

  // ── Build-time overrides (empty string ⇒ "not provided") ──────────────
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const int _apiTimeoutSecondsOverride = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 0,
  );

  /// Base URL every relative API path is resolved against. Includes the
  /// backend's `/api/v1` prefix, since request paths (`/auth/login`,
  /// `/schools/...`) are written without it.
  static String get apiBaseUrl => _baseUrlFor(_current);

  static String _baseUrlFor(Environment env) {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    switch (env) {
      case Environment.debug:
        return 'http://192.168.0.37:8000/api/v1';
      case Environment.staging:
      case Environment.prod:
        throw StateError(
          'API_BASE_URL must be explicitly set for staging/production builds.',
        );
    }
  }

  /// The server origin (scheme + host + port), i.e. [apiBaseUrl] without its
  /// `/api/vN` suffix. Static assets under `/media/...` hang off this.
  static String get serverOrigin =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

  /// Resolves a possibly-relative media path (e.g. `/media/uniform/x.png`) to an
  /// absolute URL. Absolute URLs and empty values are returned unchanged.
  static String mediaUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty || pathOrUrl.startsWith('http')) return pathOrUrl;
    final base = serverOrigin;
    final sep = pathOrUrl.startsWith('/') ? '' : '/';
    return '$base$sep$pathOrUrl';
  }

  /// Default per-request timeout (individual calls may override).
  static Duration get apiTimeout {
    if (_apiTimeoutSecondsOverride > 0) {
      return Duration(seconds: _apiTimeoutSecondsOverride);
    }
    return const Duration(seconds: 30);
  }

  /// Whether to emit request/response diagnostics. On outside production.
  static bool get verboseLogging => _current != Environment.prod;

  /// Payloads may contain passwords, tokens or child data, even in development.
  static bool get logHttpBodies => false;
}
