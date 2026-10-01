import 'dart:js_interop';
import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'session_coordinator.dart';

SessionCoordinator createCoordinator() => _BrowserCoordinator();
class _BrowserCoordinator implements SessionCoordinator {
  static const _key = 'meri_taleem.session_revision';
  // Written as a literal: on the web `1 << 32` is a 32-bit JS shift and
  // evaluates to 0, which made `nextInt` throw on every sign-in.
  static const _revisionEntropy = 0xFFFFFFFF;
  @override
  String get revision => web.window.localStorage.getItem(_key) ?? 'initial';
  @override
  void advance() => web.window.localStorage.setItem(
    _key, '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(_revisionEntropy)}');

  @override
  Future<T> exclusive<T>(Future<T> Function() action) async {
    late T result;
    Object? failure;
    StackTrace? failureStack;
    // No unsafe fallback: unavailable Web Locks is a recoverable storage error.
    final abort = web.AbortController();
    final timer = Timer(const Duration(seconds: 10), () => abort.abort());
    try {
      await web.window.navigator.locks.request('meri_taleem.credentials',
        web.LockOptions(signal: abort.signal),
        ((JSAny? _) {
          timer.cancel();
          // Capture the action's own error: one thrown through the JS promise
          // reaches the caller boxed, without its Dart type or stack trace.
          return (() async {
            try {
              result = await action();
            } catch (error, stack) {
              failure = error;
              failureStack = stack;
            }
            return null;
          })().toJS;
        }).toJS,
      ).toDart;
      if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
      return result;
    } finally { timer.cancel(); }
  }

  @override
  void Function() listen(void Function() onChanged) {
    final listener = ((web.StorageEvent event) {
      if (event.key == _key || event.key == null) onChanged();
    }).toJS;
    web.window.addEventListener('storage', listener);
    return () => web.window.removeEventListener('storage', listener);
  }
}
