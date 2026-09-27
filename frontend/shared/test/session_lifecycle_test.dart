import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

class _Store extends DataStoreService {
  String? token;
  String? refresh;
  _Store({this.token, this.refresh});
  @override
  Future<String?> readToken() async => token;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> writeToken(String value) async { token = value; }
  @override
  Future<void> writeRefreshToken(String value) async { refresh = value; }
  @override
  Future<void> deleteToken() async { token = null; }
  @override
  Future<void> deleteRefreshToken() async { refresh = null; }
  @override
  Future<void> clearAll() async { token = null; refresh = null; }
}

const profile = {'id': 'user', 'school_id': 'school', 'roles': [{'code': 'teacher'}]};
http.Response json(Object value, [int status = 200]) => http.Response(jsonEncode(value), status);

void main() {
  setUp(() => EnvConfig.bootstrap(Environment.debug));

  test('logout-all keeps credentials on failure and clears them on confirmed revocation', () async {
    final store = _Store(token: 'access', refresh: 'refresh');
    var fails = true;
    final api = ApiService(store: store, client: MockClient((request) async {
      if (request.url.path.endsWith('/logout-all')) {
        expect(request.method, 'POST');
        return fails ? json({'detail': 'Unavailable'}, 503) : http.Response('', 204);
      }
      return http.Response('', 204);
    }));
    final auth = AuthService(api: api, store: store);
    expect((await auth.logoutAll()).success, isFalse);
    expect(store.token, 'access');
    fails = false;
    expect((await auth.logoutAll()).success, isTrue);
    expect(store.token, isNull);
    expect(store.refresh, isNull);
  });

  test('login does not report success when profile hydration fails; retry can recover', () async {
    final store = _Store();
    var offline = true;
    final api = ApiService(store: store, client: MockClient((r) async {
      if (r.url.path.endsWith('/login')) return json({'access_token': 'access', 'refresh_token': 'refresh'});
      return offline ? json({'detail': 'Unavailable'}, 503) : json(profile);
    }));
    final auth = AuthService(api: api, store: store);
    final result = await auth.login(email: 'user@example.com', password: 'secret');
    expect(result.success, isFalse);
    expect(auth.isLoggedIn.value, isFalse);
    expect(auth.roleCodes, isEmpty);
    expect(store.refresh, 'refresh');
    offline = false;
    expect((await auth.fetchProfile()).success, isTrue);
    expect(auth.roleCodes, ['teacher']);
    expect(auth.isLoggedIn.value, isTrue);
  });

  test('incomplete login response cannot reuse stale credentials or profile', () async {
    final store = _Store(token: 'old', refresh: 'old-refresh');
    final api = ApiService(store: store, client: MockClient((_) async => json({})));
    final auth = AuthService(api: api, store: store)..currentUser.value = profile;
    expect((await auth.login(email: 'other@example.com', password: 'secret')).success, isFalse);
    expect(auth.currentUser.value, isNull);
    expect(store.token, isNull);
    expect(store.refresh, isNull);
  });

  test('offline logout clears local state and attempts server revocation without bearer auth', () async {
    final store = _Store(token: 'access', refresh: 'refresh');
    var calls = 0;
    final api = ApiService(store: store, client: MockClient((r) async {
      calls++;
      expect(r.url.path, '/api/v1/auth/logout');
      expect(r.headers['Authorization'], isNull);
      expect(jsonDecode(r.body)['refresh_token'], 'refresh');
      expect(store.token, isNull);
      throw http.ClientException('offline');
    }));
    final auth = AuthService(api: api, store: store)..currentUser.value = profile;
    auth.isLoggedIn.value = true;
    await Future.wait([auth.logout(), auth.logout()]);
    expect(calls, 1);
    expect(store.token, isNull);
    expect(store.refresh, isNull);
    expect(auth.currentUser.value, isNull);
    expect(auth.isLoggedIn.value, isFalse);
  });

  test('late refresh cannot restore credentials after logout', () async {
    final store = _Store(token: 'access', refresh: 'refresh');
    final arrived = Completer<void>();
    final response = Completer<http.Response>();
    final api = ApiService(store: store, client: MockClient((r) async {
      if (r.url.path.endsWith('/refresh')) { arrived.complete(); return response.future; }
      return http.Response('', 204);
    }));
    final auth = AuthService(api: api, store: store);
    final pending = auth.refreshSession();
    final checked = expectLater(pending, throwsA(isA<SessionRefreshUnavailable>()));
    await arrived.future;
    await auth.logout();
    response.complete(json({'access_token': 'late-access', 'refresh_token': 'late-refresh'}));
    await checked;
    expect(store.token, isNull);
    expect(store.refresh, isNull);
    expect(auth.isLoggedIn.value, isFalse);
  });

  test('late profile cannot restore user after logout', () async {
    final store = _Store(token: 'access');
    final arrived = Completer<void>();
    final response = Completer<http.Response>();
    final api = ApiService(store: store, client: MockClient((_) async { arrived.complete(); return response.future; }));
    final auth = AuthService(api: api, store: store);
    final pending = auth.fetchProfile();
    await arrived.future;
    await auth.logout();
    response.complete(json(profile));
    expect((await pending).success, isFalse);
    expect(auth.currentUser.value, isNull);
  });

  for (final code in [0, 503, 429]) {
    test('refresh outage $code is retryable without forcing logout', () async {
      final store = _Store(token: 'expired', refresh: 'refresh');
      final api = ApiService(store: store, client: MockClient((r) async {
        if (r.url.path.endsWith('/refresh')) {
          if (code == 0) throw http.ClientException('offline');
          return json({}, code);
        }
        return json({}, 401);
      }));
      final auth = AuthService(api: api, store: store);
      api.tokenRefresher = auth.refreshSession;
      var loggedOut = false;
      api.onUnauthorized = () { loggedOut = true; };
      final result = await api.request<dynamic>(method: HttpMethod.get, path: '/auth/me');
      expect(result.isNetworkError, isTrue);
      expect(loggedOut, isFalse);
      expect(store.refresh, 'refresh');
    });
  }

  test('late unauthorized response cannot log out a newer stored session', () async {
    final store = _Store(token: 'old');
    final arrived = Completer<void>();
    final response = Completer<http.Response>();
    final api = ApiService(store: store, client: MockClient((_) async { arrived.complete(); return response.future; }));
    var loggedOut = false;
    api.onUnauthorized = () { loggedOut = true; };
    final pending = api.request<dynamic>(method: HttpMethod.get, path: '/auth/me');
    await arrived.future;
    store.token = 'new';
    response.complete(json({}, 401));
    await pending;
    expect(loggedOut, isFalse);
    expect(store.token, 'new');
  });

  test('old write is never refreshed or replayed after switching accounts', () async {
    final store = _Store(token: 'old', refresh: 'old-refresh');
    final arrived = Completer<void>();
    final response = Completer<http.Response>();
    var writes = 0;
    var refreshes = 0;
    final api = ApiService(store: store, client: MockClient((r) async {
      if (r.url.path.endsWith('/login')) return json({'access_token': 'new', 'refresh_token': 'new-refresh'});
      if (r.url.path.endsWith('/me')) return json(profile);
      writes++;
      arrived.complete();
      return response.future;
    }));
    final auth = AuthService(api: api, store: store);
    api.tokenRefresher = () async { refreshes++; return true; };
    final pending = api.request<dynamic>(method: HttpMethod.post, path: '/old-account-action');
    await arrived.future;
    expect((await auth.login(email: 'new@example.com', password: 'secret')).success, isTrue);
    response.complete(json({}, 401));
    expect((await pending).success, isFalse);
    expect(writes, 1);
    expect(refreshes, 0);
    expect(store.token, 'new');
  });

  test('rejected refresh still marks the active session unauthorized', () async {
    final store = _Store(token: 'expired', refresh: 'revoked');
    final api = ApiService(store: store, client: MockClient((_) async => json({}, 401)));
    final auth = AuthService(api: api, store: store);
    api.tokenRefresher = auth.refreshSession;
    var unauthorized = 0;
    api.onUnauthorized = () { unauthorized++; };
    final result = await api.request<dynamic>(method: HttpMethod.get, path: '/auth/me');
    expect(result.isUnauthorized, isTrue);
    expect(unauthorized, 1);
  });

  test('late login cannot restore credentials after logout', () async {
    final store = _Store();
    final arrived = Completer<void>();
    final response = Completer<http.Response>();
    final api = ApiService(store: store, client: MockClient((_) async {
      arrived.complete();
      return response.future;
    }));
    final auth = AuthService(api: api, store: store);
    final pending = auth.login(email: 'user@example.com', password: 'secret');
    await arrived.future;
    await auth.logout();
    response.complete(json({'access_token': 'late', 'refresh_token': 'late-refresh'}));
    expect((await pending).success, isFalse);
    expect(store.token, isNull);
    expect(store.refresh, isNull);
  });

  test('session controls parse metadata and clear this device after revocation', () async {
    final store = _Store(token: 'access', refresh: 'refresh');
    var deleted = false;
    final api = ApiService(store: store, client: MockClient((request) async {
      if (request.url.path.endsWith('/sessions')) {
        return json([{'id': 'session', 'is_current': true, 'expires_at': '2030-01-01T00:00:00Z'}]);
      }
      if (request.url.path.endsWith('/sessions/session')) {
        deleted = true;
        return http.Response('', 204);
      }
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      return json({}, 404);
    }));
    final auth = AuthService(api: api, store: store);
    final sessions = await auth.listSessions();
    expect(sessions.success, isTrue);
    expect(sessions.data!.single['id'], 'session');
    await auth.revokeSession('session', isCurrent: true);
    expect(deleted, isTrue);
    expect(store.token, isNull);
    expect(store.refresh, isNull);
  });
}
