import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';

class _Store extends DataStoreService {
  @override
  Future<String?> readToken() async => 'test-token';
}

Map<String, dynamic> row(String id, {String sender = 'me', String recipient = 'peer',
    String? student, String? readAt, String created = '2026-09-15T10:00:00Z'}) => {
  'id': id, 'sender_id': sender, 'recipient_id': recipient,
  'sender_name': sender, 'recipient_name': recipient, 'student_id': student,
  'body': 'Private note', 'kind': 'message', 'read_at': readAt, 'created_at': created,
};

MessagingService boot(Future<http.Response> Function(http.Request) handler) {
  final store = _Store();
  final api = ApiService(store: store, client: MockClient(handler));
  Get.put(AuthService(api: api, store: store)..currentUser.value = {'id': 'me', 'school_id': 'school'});
  return MessagingService(api: api);
}

void main() {
  setUp(() { Get.testMode = true; EnvConfig.bootstrap(Environment.debug); });
  tearDown(() => Get.reset());

  test('conversation requests only its counterpart and excludes foreign pairs', () async {
    final service = boot((request) async {
      expect(request.url.queryParameters['counterpart_id'], 'peer');
      expect(request.url.queryParameters['box'], 'all');
      return http.Response(jsonEncode([row('mine'), row('foreign', sender: 'stranger')]), 200);
    });
    final controller = ConversationController(counterpartId: 'peer', counterpartName: 'Peer', service: service);
    await controller.load();
    expect(controller.messages.map((m) => m.id), ['mine']);
  });

  for (final explicit in [false, true]) {
    test('reply context follows ${explicit ? 'explicit student' : 'latest general message'}', () async {
      Map<String, dynamic>? sent;
      final service = boot((request) async {
        if (request.method == 'POST') {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(row('reply', student: sent?['student_id'] as String?)), 201);
        }
        return http.Response(jsonEncode([
          row('old', student: 'old-child'),
          row('latest', created: '2026-09-15T11:00:00Z'),
        ]), 200);
      });
      final controller = ConversationController(counterpartId: 'peer', counterpartName: 'Peer',
          studentId: explicit ? 'selected-child' : null, service: service);
      await controller.load();
      expect(await controller.send('Reply'), isTrue);
      expect(sent?['student_id'], explicit ? 'selected-child' : null);
      expect(controller.messages, hasLength(3));
    });
  }

  for (final success in [true, false]) {
    test('read receipt ${success ? 'updates only after persistence' : 'failure stays unread and visible'}', () async {
      final incoming = row('incoming', sender: 'peer', recipient: 'me');
      final service = boot((request) async {
        if (request.method == 'PATCH') {
          expect(request.url.path.endsWith('/incoming/read'), isTrue);
          return success ? http.Response(jsonEncode({...incoming, 'read_at': '2026-09-15T12:00:00Z'}), 200)
            : http.Response('{"detail":"Denied"}', 403);
        }
        return http.Response(jsonEncode([incoming]), 200);
      });
      final controller = ConversationController(counterpartId: 'peer', counterpartName: 'Peer', service: service);
      await controller.load();
      expect(controller.messages.single.isUnreadFor('me'), !success);
      expect(controller.error.value == null, success);
    });
  }

  test('denied send is not appended and unavailable history is cleared', () async {
    var denyRead = false;
    final service = boot((request) async {
      if (request.method == 'POST' || denyRead) return http.Response('{"detail":"Not permitted"}', 403);
      return http.Response(jsonEncode([row('mine')]), 200);
    });
    final controller = ConversationController(counterpartId: 'peer', counterpartName: 'Peer', service: service);
    await controller.load();
    expect(await controller.send('Cannot send'), isFalse);
    expect(controller.messages, hasLength(1));
    expect(controller.sending.value, isFalse);
    denyRead = true;
    await controller.load();
    expect(controller.messages, isEmpty);
    expect(controller.error.value, isNotNull);
  });

  test('grouping cannot introduce foreign messages or stale child context', () {
    final grouped = Conversation.group([
      DirectMessage.fromJson(row('old', student: 'old-child')),
      DirectMessage.fromJson(row('latest', created: '2026-09-15T11:00:00Z')),
      DirectMessage.fromJson(row('foreign', sender: 'stranger', recipient: 'someone')),
    ], 'me');
    expect(grouped, hasLength(1));
    expect(grouped.single.studentId, isNull);
    expect(grouped.single.messages, hasLength(2));
  });

  test('failed refresh clears stale contact and inbox data', () async {
    var deny = false;
    final service = boot((request) async {
      if (deny) return http.Response('{"detail":"Denied"}', 403);
      return http.Response(jsonEncode(request.url.path.endsWith('/contacts')
        ? [{'id': 'peer', 'name': 'Peer', 'role': 'teacher'}] : [row('mine')]), 200);
    });
    final contacts = NewMessageController(service: service);
    final inbox = InboxController(service: service);
    await contacts.load();
    await inbox.load();
    expect(contacts.contacts, hasLength(1));
    expect(inbox.conversations, hasLength(1));
    deny = true;
    await contacts.load();
    await inbox.load();
    expect(contacts.contacts, isEmpty);
    expect(inbox.conversations, isEmpty);
  });
}
