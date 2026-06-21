import 'package:get/get.dart';

import '../services/api_response.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/http_method.dart';

/// Thin repository over [ApiService] for the notification service, shared by the
/// doctor and patient apps. Covers FCM device-token registration and the
/// persisted notification history (list / unread / read / delete).
///
/// History calls return raw maps so each app can map them onto its own
/// notification model/enum.
class NotificationApi {
  ApiService get _api => Get.find<ApiService>();

  // ── Device tokens (FCM) ─────────────────────────────────────
  /// Register this device's FCM token so the backend can push to it. Call after
  /// login and whenever the token refreshes.
  Future<void> registerDevice({required String token, String platform = 'android'}) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/notifications/devices',
      body: {'token': token, 'platform': platform},
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to register device');
  }

  /// Stop pushes to this device (call on logout).
  Future<void> unregisterDevice(String token) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.delete,
      path: '/notifications/devices/$token',
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to unregister device');
  }

  // ── History ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.request<List<dynamic>>(
      method: HttpMethod.get,
      path: '/notifications',
      parser: (j) => j as List,
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to load notifications');
    return (res.data ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: '/notifications/unread-count',
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to load unread count');
    return ((res.rawJson?['count'] as num?) ?? 0).toInt();
  }

  Future<void> markRead(String id) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.patch,
      path: '/notifications/$id/read',
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to mark read');
  }

  Future<void> markAllRead() async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.post,
      path: '/notifications/read-all',
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to mark all read');
  }

  Future<void> remove(String id) async {
    final ApiResponse<Map<String, dynamic>> res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.delete,
      path: '/notifications/$id',
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to delete notification');
  }
}
