import 'session_coordinator_native.dart'
    if (dart.library.js_interop) 'session_coordinator_web.dart' as platform;

/// Serializes browser credential mutations. Revisions contain no credentials.
abstract class SessionCoordinator {
  factory SessionCoordinator() => platform.createCoordinator();
  String get revision;
  void advance();
  Future<T> exclusive<T>(Future<T> Function() action);
  void Function() listen(void Function() onChanged);
}
