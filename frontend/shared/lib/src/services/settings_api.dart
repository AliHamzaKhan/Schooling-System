import 'package:get/get.dart';

import 'api_exception.dart';
import 'api_service.dart';
import 'http_method.dart';

/// Thin repository over [ApiService] for the per-user settings blob, shared by
/// the doctor and patient apps.
///
/// The backend stores a free-form `preferences` map (notification toggles,
/// security flags, language/timezone, …). The path differs per module, so it's
/// injected: `/doctors/me/settings` or `/patients/me/settings`.
class SettingsApi {
  /// e.g. `/doctors/me/settings` or `/patients/me/settings`.
  final String path;

  const SettingsApi({required this.path});

  ApiService get _api => Get.find<ApiService>();

  /// Fetch the stored preferences map (empty when nothing saved yet).
  Future<Map<String, dynamic>> getPreferences() async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: path,
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to load settings');
    final prefs = res.rawJson?['preferences'];
    return prefs is Map ? Map<String, dynamic>.from(prefs) : <String, dynamic>{};
  }

  /// Persist the full preferences map; returns the stored map.
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> preferences) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: HttpMethod.put,
      path: path,
      body: {'preferences': preferences},
    );
    if (!res.success) throw ApiException(res.error ?? 'Failed to save settings');
    final prefs = res.rawJson?['preferences'];
    return prefs is Map ? Map<String, dynamic>.from(prefs) : preferences;
  }
}
