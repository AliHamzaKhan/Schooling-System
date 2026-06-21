import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/schools/models/school.dart';
import 'admin_endpoints.dart';

/// Network layer for the admin portal. Owns every admin HTTP call: it builds
/// requests through the shared [ApiService] (auth headers, base URL, error
/// surfacing) against [AdminEndpoints] and parses payloads into typed models.
///
/// Controllers never touch this class directly — they go through the feature
/// repositories (e.g. `SchoolsRepository`), which decide between this live
/// service and bundled mock data.
class AdminApiService {
  final ApiService _api;
  AdminApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  // ── Schools ─────────────────────────────────────────────────
  /// Fetches schools (backend supports `limit`/`offset` only — search and
  /// status filtering happen client-side in the repository).
  Future<ApiResponse<List<School>>> fetchSchools({
    int limit = 200,
    int offset = 0,
  }) {
    return _api.request<List<School>>(
      method: HttpMethod.get,
      path: AdminEndpoints.schools,
      query: {'limit': '$limit', 'offset': '$offset'},
      parser: (json) => (json as List)
          .map((e) => School.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<School>> createSchool(Map<String, dynamic> payload) {
    return _api.request<School>(
      method: HttpMethod.post,
      path: AdminEndpoints.schools,
      body: payload,
      parser: (json) => School.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<School>> updateSchool(
    String id,
    Map<String, dynamic> payload,
  ) {
    return _api.request<School>(
      method: HttpMethod.patch,
      path: AdminEndpoints.school(id),
      body: payload,
      parser: (json) => School.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Sets a school's lifecycle status (`pending` / `active` / `suspended`).
  Future<ApiResponse<School>> setSchoolStatus(String id, String status) {
    return _api.request<School>(
      method: HttpMethod.post,
      path: AdminEndpoints.schoolStatus(id),
      body: {'status': status},
      parser: (json) => School.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Assigns a subscription plan (`basic` / `standard` / `premium`).
  Future<ApiResponse<School>> assignSubscription(String id, String planCode) {
    return _api.request<School>(
      method: HttpMethod.post,
      path: AdminEndpoints.schoolSubscription(id),
      body: {'plan_code': planCode},
      parser: (json) => School.fromJson(json as Map<String, dynamic>),
    );
  }
}
