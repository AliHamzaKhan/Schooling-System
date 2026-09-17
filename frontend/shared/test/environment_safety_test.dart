import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

void main() {
  test('bootstrap applies build defines before services start', () {
    EnvConfig.bootstrap();
    final expected = EnvConfig.resolveEnvironment(
      const String.fromEnvironment('APP_ENV'), release: false,
    );
    expect(EnvConfig.current, expected);
    expect(EnvConfig.verboseLogging, expected != Environment.prod);
    expect(EnvConfig.logHttpBodies, isFalse);
  });

  test('non-development bootstrap has no implicit endpoint', () {
    if (const String.fromEnvironment('API_BASE_URL').isEmpty) {
      EnvConfig.bootstrap(Environment.debug);
      expect(() => EnvConfig.bootstrap(Environment.prod), throwsStateError);
      expect(() => EnvConfig.bootstrap(Environment.staging), throwsStateError);
      expect(EnvConfig.current, Environment.debug);
    }
  });

  test(
    'release defaults to production and rejects debug or unknown values',
    () {
      expect(EnvConfig.resolveEnvironment('', release: true), Environment.prod);
      expect(
        EnvConfig.resolveEnvironment('', release: false),
        Environment.debug,
      );
      expect(
        EnvConfig.resolveEnvironment('staging', release: true),
        Environment.staging,
      );
      expect(
        () => EnvConfig.resolveEnvironment('debug', release: true),
        throwsStateError,
      );
      expect(
        () => EnvConfig.resolveEnvironment('typo', release: false),
        throwsStateError,
      );
    },
  );

  test(
    'non-development endpoints reject local hosts, HTTP and URL secrets',
    () {
      for (final raw in [
        '',
        'http://school.example.com/api/v1',
        'https://localhost/api/v1',
        'https://127.0.0.1/api/v1',
        'https://127.1/api/v1',
        'https://192.168.1.2/api/v1',
        'https://10.0.0.1/api/v1',
        'https://172.16.1.1/api/v1',
        'https://[::1]/api/v1',
        'https://api.local/api/v1',
        'https://user:password@api.example.com/api/v1',
        'https://api.example.com/api/v1?token=secret',
        'https://api.example.com/api/v1#secret',
      ]) {
        expect(
          () => EnvConfig.validateApiUrl(raw, Environment.prod),
          throwsStateError,
          reason: 'Unsafe production endpoint was accepted',
        );
      }
      EnvConfig.validateApiUrl(
        'https://api.example.com/api/v1',
        Environment.prod,
      );
      EnvConfig.validateApiUrl(
        'http://127.0.0.1:8090/api/v1',
        Environment.debug,
      );
    },
  );

  test(
    'HTTP diagnostics never contain payloads, URLs, response data or exceptions',
    () async {
      EnvConfig.bootstrap(Environment.debug);
      expect(EnvConfig.logHttpBodies, isFalse);
      final logs = <String>[];
      final api = ApiService(
        store: DataStoreService(),
        diagnosticWriter: logs.add,
        client: MockClient((request) async {
          if (request.method == 'GET') {
            throw http.ClientException(
              'student-name password-secret token-secret',
              request.url,
            );
          }
          return http.Response('{"access_token":"response-secret"}', 200);
        }),
      );
      await api.request<Map<String, dynamic>>(
        method: HttpMethod.post,
        path: '/auth/login',
        requiresAuth: false,
        query: {'email': 'student-name'},
        body: {'password': 'password-secret', 'token': 'token-secret'},
      );
      await api.request(
        method: HttpMethod.get,
        path: '/student-name',
        requiresAuth: false,
      );
      expect(logs, isNotEmpty);
      final output = logs.join('\n');
      for (final value in [
        'student-name',
        'password-secret',
        'token-secret',
        'response-secret',
        '/auth/login',
      ]) {
        expect(output, isNot(contains(value)));
      }
      expect(output, contains('POST'));
      expect(output, contains('200'));
      expect(output, contains('ClientException'));
    },
  );
}
