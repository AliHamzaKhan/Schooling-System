import 'package:get/get.dart';

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

  // ── Reactive state ──────────────────────────────────────────
  final Rxn<Map<String, dynamic>> currentUser = Rxn<Map<String, dynamic>>();
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  AuthService({required this.api, required this.store});

  /// Call once after [DataStoreService.init] to restore the user's session.
  Future<void> bootstrap() async {
    final token = await store.readToken();
    isLoggedIn.value = token != null && token.isNotEmpty;
    if (isLoggedIn.value) {
      // Best-effort hydrate; on 401 the token is wiped silently.
      await fetchProfile(silent: true);
    }
  }

  // ── Endpoints (rename to match your backend) ────────────────
  Future<ApiResponse<Map<String, dynamic>>> login({required String email, required String password}) async {
    isLoading.value = true;
    try {
      final res = await api.request<Map<String, dynamic>>(
        method: HttpMethod.post,
        path: '/auth/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );
      if (res.success && res.rawJson != null) {
        final token = res.rawJson!['access_token'] as String?;
        final refresh = res.rawJson!['refresh_token'] as String?;
        if (token != null) await store.writeToken(token);
        if (refresh != null) await store.writeRefreshToken(refresh);
        isLoggedIn.value = token != null;
        await fetchProfile(silent: true);
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
  }) {
    return api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/auth/change-password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchProfile({bool silent = false}) async {
    final res = await api.request<Map<String, dynamic>>(method: HttpMethod.get, path: '/auth/me');
    if (res.success && res.rawJson != null) {
      currentUser.value = res.rawJson;
    } else if (res.isUnauthorized && silent) {
      await logout();
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

  Future<void> logout() async {
    await store.clearAll();
    currentUser.value = null;
    isLoggedIn.value = false;
  }
}
