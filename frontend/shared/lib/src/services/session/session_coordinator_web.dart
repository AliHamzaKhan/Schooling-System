import 'dart:js_interop';
import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'session_coordinator.dart';

SessionCoordinator createCoordinator() => _BrowserCoordinator();
class _BrowserCoordinator implements SessionCoordinator {
  static const _key = 'meri_taleem.session_revision';
  @override
  String get revision => web.window.localStorage.getItem(_key) ?? 'initial';
  @override
  void advance() => web.window.localStorage.setItem(
    _key, '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}');

  @override
  Future<T> exclusive<T>(Future<T> Function() action) async {
    late T result;
    // No unsafe fallback: unavailable Web Locks is a recoverable storage error.
    final abort = web.AbortController();
    final timer = Timer(const Duration(seconds: 10), () => abort.abort());
    try {
      await web.window.navigator.locks.request('meri_taleem.credentials',
        web.LockOptions(signal: abort.signal),
        ((JSAny? _) {
          timer.cancel();
          return (() async { result = await action(); return null; })().toJS;
        }).toJS,
      ).toDart;
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
