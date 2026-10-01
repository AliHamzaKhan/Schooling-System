@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:shared/src/services/session/session_coordinator.dart';
import 'package:web/web.dart' as web;

class BrowserStore extends DataStoreService {
  BrowserStore(this.tokens);
  final Map<String, String> tokens;
  @override
  Future<String?> readToken() async => tokens['access'];
  @override
  Future<String?> readRefreshToken() async => tokens['refresh'];
  @override
  Future<void> writeToken(String value) async { tokens['access'] = value; }
  @override
  Future<void> writeRefreshToken(String value) async { tokens['refresh'] = value; }
  @override
  Future<void> clearAll() async => tokens.clear();
}
void main() {
  setUp(() => EnvConfig.bootstrap(Environment.debug));
  test('independent browser clients rotate a rejected token only once', () async {
    final tokens = {'access': 'old', 'refresh': 'old-refresh'};
    var refreshes = 0;
    final submitted = <Object?>[];
    // The Web Lock callback runs outside the test zone, where `expect` throws;
    // record the request and assert after the refresh completes.
    Future<http.Response> backend(http.Request r) async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      submitted.add(jsonDecode(r.body)['refresh_token']);
      return http.Response('{"access_token":"new","refresh_token":"new-refresh"}', 200);
    }
    final a = BrowserStore(tokens), b = BrowserStore(tokens);
    final first = AuthService(api: ApiService(store: a, client: MockClient(backend)), store: a);
    final second = AuthService(api: ApiService(store: b, client: MockClient(backend)), store: b);
    addTearDown(first.onClose); addTearDown(second.onClose);
    final result = await Future.wait([
      first.refreshSession(rejectedAccessToken: 'old'),
      second.refreshSession(rejectedAccessToken: 'old'),
    ], eagerError: true);
    expect(result, [true, true]); expect(refreshes, 1);
    expect(submitted, ['old-refresh']);
  });

  test('Web Lock excludes another browsing context until release', () async {
    final coordinator = SessionCoordinator();
    final entered = Completer<void>(), release = Completer<void>();
    final waiting = Completer<void>(), acquired = Completer<void>();
    final listener = ((web.MessageEvent event) {
      final message = event.data.dartify();
      if (message == 'session-test-waiting' && !waiting.isCompleted) waiting.complete();
      if (message == 'session-test-acquired' && !acquired.isCompleted) acquired.complete();
    }).toJS;
    web.window.addEventListener('message', listener);
    final lock = coordinator.exclusive(() async { entered.complete(); await release.future; });
    await entered.future;
    final frame = web.HTMLIFrameElement()..srcdoc = '''<script>
      parent.postMessage('session-test-waiting', '*');
      navigator.locks.request('meri_taleem.credentials', () => {
        parent.postMessage('session-test-acquired', '*');
      });
    </script>'''.toJS;
    web.document.body!.appendChild(frame);
    addTearDown(() { frame.remove(); web.window.removeEventListener('message', listener); });
    await waiting.future.timeout(const Duration(seconds: 5));
    expect(acquired.isCompleted, isFalse);
    release.complete(); await lock;
    await acquired.future.timeout(const Duration(seconds: 5));
  });

  test('another browsing context invalidates old account state before further requests', () async {
    final storage = BrowserStore({'access': 'old', 'refresh': 'old-refresh'});
    var requests = 0;
    final api = ApiService(store: storage, client: MockClient((_) async { requests++; return http.Response('{}', 200); }));
    api.bindSession();
    final auth = AuthService(api: api, store: storage);
    auth.currentUser.value = {'id': 'old-user'}; auth.isLoggedIn.value = true;
    final changed = Completer<void>();
    auth.onExternalSessionChanged = () { if (!changed.isCompleted) changed.complete(); };
    final frame = web.HTMLIFrameElement()..srcdoc = '''<script>
      localStorage.setItem('meri_taleem.session_revision', 'other-context-' + Date.now());
    </script>'''.toJS;
    web.document.body!.appendChild(frame);
    addTearDown(() { frame.remove(); auth.onClose(); });
    await changed.future.timeout(const Duration(seconds: 5));
    expect(auth.currentUser.value, isNull); expect(auth.isLoggedIn.value, isFalse);
    final response = await api.request<dynamic>(method: HttpMethod.post, path: '/old-account-write');
    expect(response.success, isFalse); expect(requests, 0);
  });
  test('advancing the session revision works under JavaScript integers', () {
    // Regression: `nextInt(1 << 32)` evaluated to nextInt(0) on the web and
    // threw on every sign-in.
    final coordinator = SessionCoordinator();
    final before = coordinator.revision;
    coordinator.advance();
    expect(coordinator.revision, isNot(before));
  });
}
