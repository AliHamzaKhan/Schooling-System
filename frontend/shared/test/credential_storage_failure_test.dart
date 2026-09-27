import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> disk;
  late Set<String> failures;
  late List<String> deleted;
  setUp(() {
    EnvConfig.bootstrap(Environment.debug);
    SharedPreferences.setMockInitialValues({});
    disk = {'auth_token': 'old', 'refresh_token': 'old-refresh'};
    failures = {}; deleted = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String?;
      if (call.method == 'delete') deleted.add(key!);
      if (failures.contains('${call.method}:$key')) throw PlatformException(code: 'locked');
      switch (call.method) {
        case 'read': return disk[key];
        case 'write': disk[key!] = args['value'] as String; return null;
        case 'delete': disk.remove(key); return null;
      }
      return null;
    });
  });
  Future<DataStoreService> store() async {
    final value = DataStoreService(); await value.init(); return value;
  }
  test('header storage failure is a recoverable response with no HTTP dispatch', () async {
    final storage = await store(); failures.add('read:auth_token');
    var calls = 0;
    final api = ApiService(store: storage, client: MockClient((_) async { calls++; return http.Response('{}', 200); }));
    final response = await api.request<dynamic>(method: HttpMethod.get, path: '/auth/me');
    expect(response.isNetworkError, isTrue); expect(calls, 0);
  });
  test('logout attempts both deletes even when reads and first delete fail; restart stays signed out', () async {
    final storage = await store();
    failures.addAll(['read:refresh_token', 'delete:auth_token']);
    final auth = AuthService(api: ApiService(store: storage), store: storage);
    await auth.logout();
    expect(deleted, containsAll(['auth_token', 'refresh_token']));
    expect(auth.isLoggedIn.value, isFalse);
    expect(auth.sessionNotice.value, contains('could not be fully removed'));
    expect(await (await store()).readToken(), isNull);
    failures.clear(); await auth.logout();
    expect(disk, isEmpty); expect(auth.sessionNotice.value, isNull);
  });
  test('partial login write is never restorable; retry saves a complete pair', () async {
    final storage = await store(); failures.add('write:refresh_token');
    final api = ApiService(store: storage, client: MockClient((r) async => http.Response(jsonEncode(
      r.url.path.endsWith('/login') ? {'access_token': 'new', 'refresh_token': 'new-refresh'} : {'id': 'user', 'roles': [{'code': 'teacher'}]}
    ), 200)));
    final auth = AuthService(api: api, store: storage);
    expect((await auth.login(email: 'test@example.com', password: 'test')).success, isFalse);
    expect(auth.isLoggedIn.value, isFalse);
    expect(await (await store()).readToken(), isNull);
    failures.clear();
    expect((await auth.login(email: 'test@example.com', password: 'test')).success, isTrue);
    expect(await storage.readRefreshToken(), 'new-refresh');
  });
  test('bootstrap storage failure exposes retry without false signed-in state', () async {
    final storage = await store(); failures.add('read:auth_token');
    final auth = AuthService(api: ApiService(store: storage, client: MockClient((_) async => http.Response('{"id":"user","roles":[]}', 200))), store: storage);
    await auth.bootstrap();
    expect(auth.restoreError.value, contains('Secure storage')); expect(auth.isLoggedIn.value, isFalse);
    failures.clear(); await auth.bootstrap();
    expect(auth.restoreError.value, isNull); expect(auth.isLoggedIn.value, isTrue);
  });
}
