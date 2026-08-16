// Cold-start routing: what the splash decides, for each way a launch can go.
//
// This is the one screen every launch passes through, and its three outcomes
// (no session → login, valid session → the role's shell, server unreachable →
// retry) are only reachable on a real device under conditions that are awkward
// to reproduce by hand. Driving the real AuthService against an in-memory
// backend pins all three.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_portal/school/config/app_routes.dart';
import 'package:school_portal/school/config/role_home.dart';
import 'package:school_portal/school/constants/app_strings.dart';
import 'package:school_portal/school/modules/splash/controller/splash_controller.dart';
import 'package:school_portal/school/modules/splash/view/splash_view.dart';

const _secureChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// `/auth/me` answers with [roles]; null makes every request fail at the
/// transport layer, standing in for a server that cannot be reached.
http.Client _backend({List<String>? roles}) {
  return MockClient((req) async {
    if (roles == null) {
      throw http.ClientException('Failed to fetch', req.url);
    }
    if (req.url.path.endsWith('/auth/me')) {
      return http.Response(
        jsonEncode({
          'id': 'u1',
          'email': 'user@test.edu',
          'full_name': 'Test User',
          'is_active': true,
          'school_id': 'school-1',
          'roles': [
            for (final code in roles)
              {'id': 'r-$code', 'code': code, 'name': code, 'is_system': false},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(jsonEncode({'detail': 'not found'}), 404);
  });
}

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

/// Boots the real service graph against [client], optionally with a stored
/// token already in place (i.e. a returning user).
Future<AuthService> _boot({
  required http.Client client,
  String? storedToken,
}) async {
  _mockSecureStorage();
  SharedPreferences.setMockInitialValues({});
  EnvConfig.bootstrap(Environment.debug);

  final store = DataStoreService();
  await store.init();
  if (storedToken != null) await store.writeToken(storedToken);

  final api = ApiService(client: client, store: store);
  final auth = AuthService(api: api, store: store);

  Get.reset();
  Get.put<DataStoreService>(store, permanent: true);
  Get.put<ApiService>(api, permanent: true);
  Get.put<AuthService>(auth, permanent: true);
  return auth;
}

/// Every route the splash can send someone to, as an empty page. Real shells
/// would boot their own controllers and fire their own requests; the assertion
/// here is only about *which* route was chosen.
final _stubPages = <GetPage>[
  for (final name in [
    '/boot',
    AuthRoutes.login,
    AppRoutes.headmaster,
    AppRoutes.teacher,
    AppRoutes.student,
    AppRoutes.guardian,
  ])
    GetPage(name: name, page: () => const SizedBox.shrink()),
];

/// Runs the splash's decision inside a real GetX navigator and reports the
/// route it landed on, or null when it stayed put.
Future<String?> _resolvedRoute(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/boot',
    getPages: _stubPages,
  ));
  await tester.pump();

  final controller = SplashController();
  final done = controller.resolve();
  // The splash holds for a minimum dwell before navigating.
  await tester.pump(const Duration(seconds: 2));
  await done;
  await tester.pumpAndSettle();

  return Get.currentRoute == '/boot' ? null : Get.currentRoute;
}

void main() {
  tearDown(Get.reset);

  testWidgets('no stored session lands on login', (tester) async {
    await _boot(client: _backend(roles: const ['student']));
    expect(await _resolvedRoute(tester), AuthRoutes.login);
  });

  // One test per role rather than a loop: each needs its own fresh GetX
  // registry, and resetting it mid-test tears the navigator out from under the
  // app already pumped into the tree.
  for (final role in ['headmaster', 'teacher', 'student', 'guardian']) {
    testWidgets('a valid $role session lands on the $role shell',
        (tester) async {
      await _boot(client: _backend(roles: [role]), storedToken: 'stored-token');
      expect(await _resolvedRoute(tester), homeRouteForRoles([role]));
    });
  }

  testWidgets('a rejected token signs the user out and lands on login',
      (tester) async {
    await _boot(
      client: MockClient(
          (_) async => http.Response(jsonEncode({'detail': 'nope'}), 401)),
      storedToken: 'expired-token',
    );
    expect(await _resolvedRoute(tester), AuthRoutes.login);
  });

  testWidgets('the splash renders branding while working, and a retry when the '
      'server is unreachable', (tester) async {
    await _boot(client: _backend(), storedToken: 'stored-token');
    final controller = Get.put(SplashController());

    // A phone viewport: the splash is a full-bleed layout, so a regression that
    // overflows it would throw here rather than on someone's device.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: SplashView()));
    await tester.pump();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Kick off the resolve, then advance the test clock past the minimum dwell.
    // Awaiting it before pumping would deadlock: the delay runs on the fake
    // clock, which only moves when the tester pumps.
    final done = controller.resolve();
    await tester.pump(const Duration(seconds: 2));
    await done;
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('an unreachable server keeps the session and offers a retry', () async {
    final auth = await _boot(client: _backend(), storedToken: 'stored-token');
    final controller = SplashController();

    await controller.resolve();

    // The user is neither routed onward nor signed out: the token is probably
    // fine, the network is not. Routing on the empty role list this leaves
    // behind is exactly the bug this case exists to prevent.
    expect(controller.outcome.value, SplashOutcome.unreachable);
    expect(auth.isLoggedIn.value, isTrue);
  });
}
