import 'package:get/get.dart';

import '../features/auth/auth_routes.dart';
import '../features/auth/session_navigation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/data_store_service.dart';

/// Registers the core singletons every portal needs (storage → API → auth) and
/// restores any existing session. Call once in `main()` after
/// `EnvConfig.bootstrap(...)` and before `runApp`.
///
/// On a session-fatal failure from an authenticated call — an unrecoverable
/// 401, or a tenant/subscription/account failure the backend flags via
/// `error.code` — the session is cleared and the app is routed back to the
/// shared login.
///
/// Set [restoreSession] to false when the app has a splash screen that owns the
/// restore itself. Session restore calls `/auth/me`, and awaiting it here means
/// blocking `runApp` on a network round trip — the window stays blank for as
/// long as the server takes, with nothing on screen to explain the wait and no
/// way to report that the server is unreachable. A splash can show branding
/// immediately, run the same restore, and route (or offer a retry) when it
/// finishes.
Future<void> initSharedServices({bool restoreSession = true}) async {
  final store = DataStoreService();
  try { await store.init(); } catch (_) { /* Restore UI offers retry. */ }

  final api = ApiService(store: store);
  final auth = AuthService(api: api, store: store);

  // On a 401, ApiService first tries to renew the access token via the refresh
  // token; only if that fails (or the failure is a tenant/subscription one a
  // refresh can't fix) does onUnauthorized fire (clear session + login).
  api.tokenRefresherForToken = (token) => auth.refreshSession(rejectedAccessToken: token);
  api.onUnauthorized = () async {
    final target = SessionNavigation.safeTarget(Get.currentRoute);
    await auth.logout();
    if (Get.key.currentState != null) Get.offAllNamed(SessionNavigation.loginFor(target));
  };
  auth.onExternalSessionChanged = () {
    // Drop every route/controller from the previous account before rehydration.
    if (Get.key.currentState != null) Get.offAllNamed(AuthRoutes.restore);
  };

  Get.put<DataStoreService>(store, permanent: true);
  Get.put<ApiService>(api, permanent: true);
  Get.put<AuthService>(auth, permanent: true);

  if (restoreSession) await auth.bootstrap();
}
