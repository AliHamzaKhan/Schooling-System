import 'environment.dart';

/// Central, environment-aware configuration read by the shared services
/// ([ApiService], ads, notifications). Call [bootstrap] exactly once during app
/// startup — before `runApp` — passing the [Environment] the app should run as.
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

  static Environment _current = Environment.debug;

  /// The environment selected at startup. Defaults to [Environment.debug] until
  /// [bootstrap] is called, so reads never throw before initialization.
  static Environment get current => _current;

  /// Select the runtime [Environment]. Call once, before `runApp`.
  static void bootstrap(Environment env) => _current = env;

  // ── Build-time overrides (empty string ⇒ "not provided") ──────────────
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const int _apiTimeoutSecondsOverride =
      int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 0);

  /// Base URL every relative API path is resolved against. Includes the
  /// backend's `/api/v1` prefix, since request paths (`/auth/login`,
  /// `/schools/...`) are written without it.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    switch (_current) {
      case Environment.debug:
        return 'http://192.168.0.35:8000/api/v1';
      case Environment.staging:
        return 'https://staging.api.schooling.app/api/v1';
      case Environment.prod:
        return 'https://api.schooling.app/api/v1';
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

  /// Whether to log full HTTP request bodies. Debug only, to avoid leaking
  /// payloads (tokens, PII) in staging/production logs.
  static bool get logHttpBodies => _current == Environment.debug;
}
