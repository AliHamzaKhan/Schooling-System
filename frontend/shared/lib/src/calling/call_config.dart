/// Configuration for the video-calling engine.
///
/// The only hard requirement is [appId] — the Agora App ID for your project.
/// Tokens are per-call and supplied via [CallSession.token], not here.
///
/// Set once at boot:
/// ```dart
/// CallConfig.configure(appId: 'YOUR_AGORA_APP_ID');
/// ```
class CallConfig {
  CallConfig._();

  static String _appId = '';

  /// The Agora App ID. Empty until [configure] is called.
  static String get appId => _appId;

  static void configure({required String appId}) {
    _appId = appId;
  }

  /// True once a non-empty App ID has been provided.
  static bool get isConfigured => _appId.isNotEmpty;
}
