/// The runtime environment the app was built/booted for. Selected once at
/// startup via [EnvConfig.bootstrap] and used to pick API endpoints, timeouts,
/// and logging verbosity.
enum Environment {
  /// Local development against a backend on `localhost` (verbose logging).
  debug,

  /// Pre-production / QA environment.
  staging,

  /// Production build (quiet logging, real endpoints).
  prod,
}
