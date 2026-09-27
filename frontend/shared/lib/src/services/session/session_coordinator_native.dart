import 'session_coordinator.dart';

SessionCoordinator createCoordinator() => _NativeCoordinator();
class _NativeCoordinator implements SessionCoordinator {
  int _revision = 0;
  @override
  String get revision => '$_revision';
  @override
  void advance() => _revision++;
  @override
  Future<T> exclusive<T>(Future<T> Function() action) => action();
  @override
  void Function() listen(void Function() onChanged) => () {};
}
