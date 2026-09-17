import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

class _TokenStore extends DataStoreService {
  @override
  Future<String?> readToken() async => 'account-test-token';
}

void main() {
  const base = 'https://school.example/api/v1';
  test('ticket links stay on the configured API origin', () {
    final uri = AttachmentAccessService.validateTicketPath(
      '/api/v1/file-download?ticket=short-lived',
      base,
    );
    expect(uri.origin, 'https://school.example');
    expect(uri.path, '/api/v1/file-download');
  });

  test(
    'rejects redirects, extra parameters and malformed ticket responses',
    () {
      for (final value in <dynamic>[
        null,
        {},
        '',
        '//evil.example/api/v1/file-download?ticket=x',
        'https://evil.example/api/v1/file-download?ticket=x',
        '/api/v1/file-download?ticket=',
        '/api/v1/file-download',
        '/api/v1/file-download?ticket=a&ticket=b',
        '/api/v1/file-download?ticket=a&redirect=https://evil.example',
        '/api/v1/file-download?ticket=a#fragment',
        '/media/private/a',
        '/api/v1/../file-download?ticket=a',
      ]) {
        expect(
          () => AttachmentAccessService.validateTicketPath(value, base),
          throwsStateError,
        );
      }
    },
  );

  test('requests a fresh record ticket without persisting its URL', () async {
    EnvConfig.bootstrap(Environment.debug);
    var calls = 0;
    final service = AttachmentAccessService(
      ApiService(
        store: _TokenStore(),
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer account-test-token');
          expect(
            request.url.path,
            '/api/v1/schools/school/files/submissions/record/ticket',
          );
          return http.Response(
            '{"path":"/api/v1/file-download?ticket=fresh$calls"}',
            200,
          );
        }),
      ),
    );
    final one = await service.downloadUri(
      schoolId: 'school',
      kind: 'submissions',
      recordId: 'record',
    );
    final two = await service.downloadUri(
      schoolId: 'school',
      kind: 'submissions',
      recordId: 'record',
    );
    expect(calls, 2);
    expect(one, isNot(two));
  });

  test(
    'denied or missing record never falls back to the raw stored URL',
    () async {
      final service = AttachmentAccessService(
        ApiService(
        store: _TokenStore(),
          client: MockClient(
            (_) async => http.Response('{"detail":"Denied"}', 403),
          ),
        ),
      );
      await expectLater(
        service.downloadUri(
          schoolId: 'school',
          kind: 'documents',
          recordId: 'record',
        ),
        throwsStateError,
      );
      await expectLater(
        service.downloadUri(
          schoolId: 'school',
          kind: 'submissions',
          recordId: '',
        ),
        throwsStateError,
      );
    },
  );
}
