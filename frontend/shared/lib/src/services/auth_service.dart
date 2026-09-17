import 'package:get/get.dart';

import '../env/env_config.dart';
import 'api_response.dart';
import 'api_service.dart';
import 'data_store_service.dart';
import 'http_method.dart';

/// Reactive auth state + login/logout flows on top of [ApiService] and
/// [DataStoreService].
///
/// Extends [GetxService] so it can be put once at boot with
/// `Get.put(AuthService(...), permanent: true)` and pulled from anywhere
/// via `Get.find<AuthService>()`.
///
/// The actual endpoint paths are kept here in one place — change them to
/// match your backend contract.
class AuthService extends GetxService {
  final ApiService api;
  final DataStoreService store;
  int _sessionEpoch = 0;
  Future<void> _storeTail = Future.value();
  Future<void>? _logoutInFlight;

  Future<T> _sessionStore<T>(Future<T> Function() action) {
    final result = _storeTail.then((_) => action());
    _storeTail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  // ── Reactive state ──────────────────────────────────────────
  final Rxn<Map<String, dynamic>> currentUser = Rxn<Map<String, dynamic>>();
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  AuthService({required this.api, required this.store});

  /// The signed-in user's school id (backend `school_id`), or null for users
  /// not scoped to a school (e.g. super-admin). Needed to build school-scoped
  /// endpoints like `/schools/{school_id}/users`.
  String? get schoolId => currentUser.value?['school_id']?.toString();

  /// The signed-in user's own id (backend `id`), or null before the profile is
  /// loaded. Used to tell "my" messages from the other party's in conversations.
  String? get userId => currentUser.value?['id']?.toString();

  /// The signed-in user's display name (backend `full_name`), or null before
  /// the profile is loaded.
  String? get fullName => currentUser.value?['full_name']?.toString();

  /// The signed-in user's school/campus name, when the `/auth/me` payload
  /// carries a nested `school` object (or a flat `school_name`). Null before
  /// the profile loads or for users not scoped to a school. Used by the campus
  /// banner shown on every role's home page.
  String? get schoolName {
    final school = currentUser.value?['school'];
    if (school is Map) {
      final n = school['name']?.toString().trim() ?? '';
      if (n.isNotEmpty) return n;
    }
    final flat = currentUser.value?['school_name']?.toString().trim() ?? '';
    return flat.isEmpty ? null : flat;
  }

  /// The signed-in user's profile photo as an absolute URL, or null when they
  /// have none. The backend stores it inside `profile_metadata.avatar_url` and
  /// the local storage backend returns a host-relative path (`/media/...`), so
  /// it is resolved against the API host before use.
  String? get avatarUrl {
    final meta = currentUser.value?['profile_metadata'];
    if (meta is! Map) return null;
    final raw = meta['avatar_url']?.toString().trim() ?? '';
    return raw.isEmpty ? null : EnvConfig.mediaUrl(raw);
  }

  /// Role codes for the signed-in user (e.g. `headmaster`, `teacher`,
  /// `student`, `guardian`), parsed from the `/auth/me` `roles[]` payload.
  /// Empty until [fetchProfile] has populated [currentUser].
  List<String> get roleCodes {
    final roles = currentUser.value?['roles'];
    if (roles is! List) return const [];
    return roles
        .whereType<Map>()
        .map((r) => r['code']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Call once after [DataStoreService.init] to restore the user's session.
  Future<void> bootstrap() async {
    currentUser.value = null;
    final token = await store.readToken();
    isLoggedIn.value = token != null && token.isNotEmpty;
    if (isLoggedIn.value) {
      // Best-effort hydrate; on 401 the token is wiped silently.
      await fetchProfile(silent: true);
    }
  }

  // ── Endpoints ───────────────────────────────────────────────
  /// OAuth2 password login. The backend's `/auth/login` expects a
  /// form-urlencoded body with `username` (the email) + `password`, and returns
  /// `{access_token, refresh_token, token_type}` (no envelope).
  Future<ApiResponse<Map<String, dynamic>>> login({required String email, required String password}) async {
    final epoch = ++_sessionEpoch;
    api.invalidateSessionRequests();
    currentUser.value = null;
    isLoggedIn.value = false;
    isLoading.value = true;
    try {
      await _sessionStore(() async {
        if (epoch != _sessionEpoch) return;
        await store.deleteToken();
        await store.deleteRefreshToken();
      });
      final res = await api.request<Map<String, dynamic>>(
        method: HttpMethod.post,
        path: '/auth/login',
        body: {'username': email, 'password': password},
        requiresAuth: false,
        asForm: true,
      );
      if (res.success && res.rawJson != null) {
        final token = res.rawJson!['access_token'] as String?;
        final refresh = res.rawJson!['refresh_token'] as String?;
        if (token == null || token.isEmpty || refresh == null || refresh.isEmpty) {
          return ApiResponse.fail('The sign-in response was incomplete. Please retry.');
        }
        await _sessionStore(() async {
          if (epoch != _sessionEpoch) return;
          await store.writeToken(token);
          await store.writeRefreshToken(refresh);
        });
        if (epoch != _sessionEpoch) return ApiResponse.fail('Sign-in was cancelled.', statusCode: 401);
        final profile = await fetchProfile(silent: true);
        if (!profile.success) return profile;
      } else if (res.success) {
        return ApiResponse.fail('The sign-in response was incomplete. Please retry.');
      }
      return res;
    } finally {
      isLoading.value = false;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> register(Map<String, dynamic> payload) async {
    isLoading.value = true;
    try {
      final res = await api.request<Map<String, dynamic>>(
        method: HttpMethod.post,
        path: '/auth/register',
        body: payload,
        requiresAuth: false,
      );
      if (res.success && res.rawJson != null) {
        final token = res.rawJson!['access_token'] as String?;
        final refresh = res.rawJson!['refresh_token'] as String?;
        if (token != null) await store.writeToken(token);
        if (refresh != null) await store.writeRefreshToken(refresh);
        isLoggedIn.value = token != null;
        if (token != null) currentUser.value = res.rawJson;
      }
      return res;
    } finally {
      isLoading.value = false;
    }
  }

  /// Request a password-reset link/OTP for [email]. No auth required.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({required String email}) {
    return api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/forgot-password',
      body: {'email': email},
      requiresAuth: false,
    );
  }

  /// Verify the OTP/code delivered to [email]. On success the backend returns a
  /// short-lived `reset_token` to authorize the subsequent [resetPassword] call.
  /// No auth required.
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String code,
  }) {
    return api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/verify-otp',
      body: {'email': email, 'code': code},
      requiresAuth: false,
    );
  }

  /// Complete a reset using the token/OTP delivered to the user. No auth required.
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/reset-password',
      body: {'token': token, 'new_password': newPassword},
      requiresAuth: false,
    );
  }

  /// Change the signed-in user's password. Requires a valid session.
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/change-password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
    if (res.success) await logout();
    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchProfile({bool silent = false}) async {
    final epoch = _sessionEpoch;
    final res = await api.request<Map<String, dynamic>>(method: HttpMethod.get, path: '/auth/me');
    if (epoch != _sessionEpoch) return ApiResponse.fail('Session changed.', statusCode: 401);
    if (res.success && res.rawJson != null && res.rawJson!['id'] != null && res.rawJson!['roles'] is List) {
      currentUser.value = res.rawJson;
      isLoggedIn.value = true;
    } else if (res.isUnauthorized && silent) {
      await logout();
    } else {
      currentUser.value = null;
      if (res.success) return ApiResponse.fail('The profile could not be loaded. Please retry.');
    }
    return res;
  }

  /// Self-service account deactivation (soft pause). On success the local
  /// session is cleared — signing back in later reactivates the account.
  Future<ApiResponse<Map<String, dynamic>>> deactivateAccount() async {
    final res = await api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/me/deactivate',
    );
    if (res.success) await logout();
    return res;
  }

  /// Exchanges the stored refresh token for a new access token via
  /// `/auth/refresh`. Returns true when a fresh access token was stored. Wired
  /// into [ApiService.tokenRefresher] so an expired access token is renewed
  /// transparently on the next authenticated call instead of forcing a logout.
  Future<bool> refreshSession() async {
    final epoch = _sessionEpoch;
    final refresh = await store.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    final res = await api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/refresh',
      body: {'refresh_token': refresh},
      requiresAuth: false,
    );
    if (epoch != _sessionEpoch) throw SessionRefreshUnavailable();
    if (res.isNetworkError || res.isServerError || res.statusCode == 429) {
      throw SessionRefreshUnavailable();
    }
    if (res.success && res.rawJson != null) {
      final token = res.rawJson!['access_token'] as String?;
      final newRefresh = res.rawJson!['refresh_token'] as String?;
      if (token == null || token.isEmpty || newRefresh == null || newRefresh.isEmpty) {
        throw SessionRefreshUnavailable();
      }
      var saved = false;
      await _sessionStore(() async {
        if (epoch != _sessionEpoch) return;
        await store.writeToken(token);
        await store.writeRefreshToken(newRefresh);
        saved = true;
      });
      if (epoch != _sessionEpoch) throw SessionRefreshUnavailable();
      return saved;
    }
    return false;
  }

  Future<void> logout() => _logoutInFlight ??= _logout().whenComplete(() => _logoutInFlight = null);

  Future<void> _logout() async {
    ++_sessionEpoch;
    api.invalidateSessionRequests();
    currentUser.value = null;
    isLoggedIn.value = false;
    final refresh = await _sessionStore(() async {
      String? value;
      try {
        value = await store.readRefreshToken();
      } finally {
        await store.clearAll();
      }
      return value;
    });
    if (refresh != null && refresh.isNotEmpty) {
      // Local credentials are already gone. Offline logout never restores them.
      await api.request<dynamic>(method: HttpMethod.post, path: '/auth/logout',
        body: {'refresh_token': refresh}, requiresAuth: false,
        timeout: const Duration(seconds: 2));
    }
  }
}
