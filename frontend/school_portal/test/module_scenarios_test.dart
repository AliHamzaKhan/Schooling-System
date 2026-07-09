// Cross-module scenario tests for the School Portal.
//
// These drive the app's *real* data layer (shared ApiService + AuthService and
// the Teacher module's API service) against an in-memory HTTP backend, so a
// regression that breaks how modules connect — auth session propagating into
// school-scoped calls, envelope parsing, per-module path building — is caught
// without a live server. Each test is one connected story across modules.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared/shared.dart';

import 'package:school_portal/school/modules/teacher/data/teacher_api_service.dart';

const _secureChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// A recorded request so scenarios can assert what the module layer sent.
final List<http.Request> sentRequests = [];

/// Routes an incoming request to canned backend JSON, mirroring the real API
/// (bare payloads, no envelope) for the endpoints the scenario touches.
http.Client _backend({required String schoolId}) {
  return MockClient((req) async {
    sentRequests.add(req as http.Request? ?? http.Request(req.method, req.url));
    final path = req.url.path;
    Object? body;

    if (path.endsWith('/auth/login')) {
      body = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
      };
    } else if (path.endsWith('/auth/me')) {
      body = {
        'id': 'teacher-1',
        'email': 'teacher@test.edu',
        'full_name': 'Teacher User',
        'school_id': schoolId,
        'roles': ['teacher'],
      };
    } else if (path.endsWith('/academic/classes')) {
      body = [
        {'id': 'c1', 'name': 'Grade 1', 'level': 1},
        {'id': 'c2', 'name': 'Grade 2', 'level': 2},
      ];
    } else if (path.endsWith('/homework/assignments')) {
      body = [
        {'id': 'a1', 'title': 'Worksheet 1', 'due_date': '2999-01-01'},
        {'id': 'a2', 'title': 'Old Essay', 'due_date': '2000-01-01'},
      ];
    } else if (path.endsWith('/communication/broadcasts')) {
      body = [
        {'id': 'm1', 'title': 'Sports Day', 'body': 'Bring water bottles',
         'sent_at': '2026-07-01T09:00:00Z'},
      ];
    } else {
      return http.Response(jsonEncode({'detail': 'not found'}), 404);
    }
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
}

/// In-memory flutter_secure_storage so token read/write works headless.
void _mockSecureStorage() {
  final store = <String, String>{};
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureChannel, (call) async {
    final args = (call.arguments as Map?) ?? const {};
    switch (call.method) {
      case 'write':
        store[args['key'] as String] = args['value'] as String;
        return null;
      case 'read':
        return store[args['key'] as String];
      case 'delete':
        store.remove(args['key'] as String);
        return null;
      case 'containsKey':
        return store.containsKey(args['key'] as String);
      case 'readAll':
        return Map<String, String>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      default:
        return null;
    }
  });
}

Future<AuthService> _bootServices({required String schoolId}) async {
  _mockSecureStorage();
  SharedPreferences.setMockInitialValues({});
  EnvConfig.bootstrap(Environment.debug);

  final store = DataStoreService();
  await store.init();
  final api = ApiService(client: _backend(schoolId: schoolId), store: store);
  final auth = AuthService(api: api, store: store);

  Get.reset();
  Get.put<DataStoreService>(store, permanent: true);
  Get.put<ApiService>(api, permanent: true);
  Get.put<AuthService>(auth, permanent: true);
  return auth;
}

void main() {
  setUp(sentRequests.clear);

  testWidgets('scenario: teacher signs in then reads across modules',
      (tester) async {
    const sid = 'school-123';
    final auth = await _bootServices(schoolId: sid);

    // 1) Auth module: login stores the token and resolves the school context
    //    that every other module's calls are scoped to.
    final login = await auth.login(email: 'teacher@test.edu', password: 'pw');
    expect(login.success, isTrue);
    expect(auth.schoolId, sid);
    expect(await Get.find<DataStoreService>().readToken(), 'test-access-token');

    final teacher = TeacherApiService();

    // 2) Academic module: classes come back scoped to the signed-in school.
    final classes = await teacher.fetchClasses();
    expect(classes.success, isTrue);
    expect(classes.data!.map((c) => c.subject), ['Grade 1', 'Grade 2']);
    expect(sentRequests.last.url.path, '/api/v1/schools/$sid/academic/classes');
    // Session propagated: the school-scoped call carried the bearer token.
    expect(sentRequests.last.headers['Authorization'], 'Bearer test-access-token');

    // 3) Homework module: due-date logic splits active vs. closed.
    final assignments = await teacher.fetchAssignments();
    expect(assignments.success, isTrue);
    expect(assignments.data!.assignments.length, 2);
    expect(assignments.data!.stats.activeCount, 1); // only the future-dated one

    // 4) Communication module: broadcasts map into message threads.
    final messages = await teacher.fetchMessages();
    expect(messages.success, isTrue);
    expect(messages.data!.single.senderName, 'Sports Day');
    expect(messages.data!.single.preview, 'Bring water bottles');
  });

  testWidgets('scenario: broadcast search filters client-side across the feed',
      (tester) async {
    await _bootServices(schoolId: 's1');
    await Get.find<AuthService>().login(email: 'teacher@test.edu', password: 'pw');
    final teacher = TeacherApiService();

    final hit = await teacher.fetchMessages(query: 'sports');
    expect(hit.data!.length, 1);
    final miss = await teacher.fetchMessages(query: 'nonexistent');
    expect(miss.data, isEmpty);
  });
}
