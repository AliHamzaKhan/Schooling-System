import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

class SessionAuth extends AuthService {
  SessionAuth() : super(api: ApiService(store: DataStoreService()), store: DataStoreService());
  bool failLoad = false, failRevoke = false;
  int revocations = 0;
  Completer<ApiResponse<dynamic>>? pending;
  List<Map<String, dynamic>> sessions = [
    {'id': 'current', 'is_current': true, 'created_at': '2026-09-26T10:00:00Z'},
    {'id': 'other', 'is_current': false},
  ];
  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> listSessions() async => failLoad ? ApiResponse.fail('offline') : ApiResponse.ok(sessions);
  @override
  Future<ApiResponse<dynamic>> revokeSession(String id, {required bool isCurrent}) async {
    revocations++;
    if (pending != null) return pending!.future;
    if (failRevoke) return ApiResponse.fail('offline');
    sessions = sessions.where((s) => s['id'] != id).toList();
    return ApiResponse.ok(null);
  }
  @override
  Future<ApiResponse<dynamic>> logoutAll() => revokeSession('all', isCurrent: true);
}
void main() {
  setUp(() => EnvConfig.bootstrap(Environment.debug));
  Future<void> open(WidgetTester t, SessionAuth a, {VoidCallback? exit}) async {
    await t.pumpWidget(MaterialApp(home: SessionsView(auth: a, onSignedOut: exit ?? () {})));
    await t.pumpAndSettle();
  }
  Future<void> confirm(WidgetTester t, Finder action) async {
    await t.tap(action); await t.pumpAndSettle();
    await t.tap(find.text('Confirm')); await t.pumpAndSettle();
  }
  testWidgets('load retry recovers and failed refresh clears stale rows', (t) async {
    final a = SessionAuth()..failLoad = true;
    await open(t, a);
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    a.failLoad = false;
    await t.tap(find.text('Refresh sessions')); await t.pumpAndSettle();
    expect(find.text('Current session'), findsOneWidget);
    a.failLoad = true;
    await t.tap(find.text('Refresh sessions')); await t.pumpAndSettle();
    expect(find.text('Current session'), findsNothing);
  });
  testWidgets('failed revoke retains session and retry removes it', (t) async {
    final a = SessionAuth()..failRevoke = true;
    await open(t, a);
    await confirm(t, find.text('Revoke session').last);
    expect(find.textContaining('not confirmed'), findsOneWidget);
    expect(find.text('Other session 2'), findsOneWidget);
    a.failRevoke = false;
    await confirm(t, find.text('Revoke session').last);
    expect(find.text('Other session 2'), findsNothing);
  });
  testWidgets('global revoke locks duplicate actions and waits for confirmation', (t) async {
    final a = SessionAuth()..pending = Completer<ApiResponse<dynamic>>();
    var exits = 0;
    await open(t, a, exit: () => exits++);
    await confirm(t, find.text('Sign out everywhere'));
    expect(a.revocations, 1);
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(exits, 0);
    a.pending!.complete(ApiResponse.ok(null)); await t.pumpAndSettle();
    expect(exits, 1);
  });
  testWidgets('cancel makes no request and current revocation exits', (t) async {
    final a = SessionAuth(); var exits = 0;
    await open(t, a, exit: () => exits++);
    await t.tap(find.text('Revoke session').first); await t.pumpAndSettle();
    await t.tap(find.text('Cancel')); await t.pumpAndSettle();
    expect(a.revocations, 0);
    await confirm(t, find.text('Revoke session').first);
    expect(exits, 1);
  });
  testWidgets('small phone and 200 percent text have no overflow', (t) async {
    t.view.physicalSize = const Size(320, 640); t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize); addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)), child: child!), home: SessionsView(auth: SessionAuth(), onSignedOut: () {})));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Sign out everywhere'), 300);
    expect(t.takeException(), isNull);
  });
}
