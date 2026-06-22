import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/headmasters/models/headmaster.dart';
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

  // ── Headmasters ─────────────────────────────────────────────
  /// There is no global headmasters endpoint, so this aggregates: list schools,
  /// then per school fetch its `headmaster`-role users (N+1, fine for the admin
  /// scale). The school name is carried onto each headmaster row.
  Future<ApiResponse<List<Headmaster>>> fetchHeadmasters() async {
    final schools = await _api.request<List<Map<String, dynamic>>>(
      method: HttpMethod.get,
      path: AdminEndpoints.schools,
      query: {'limit': '200'},
      parser: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    if (!schools.success || schools.data == null) {
      return ApiResponse.fail(schools.error ?? 'Could not load schools.',
          statusCode: schools.statusCode);
    }

    final out = <Headmaster>[];
    for (final s in schools.data!) {
      final sid = '${s['id']}';
      final sname = s['name'] as String?;
      final res = await _api.request<List<Headmaster>>(
        method: HttpMethod.get,
        path: AdminEndpoints.schoolUsers(sid),
        query: {'role_code': 'headmaster', 'limit': '50'},
        parser: (json) => (json as List).cast<Map<String, dynamic>>().map((u) {
          return Headmaster(
            id: '${u['id']}',
            name: u['full_name'] as String? ?? '',
            email: u['email'] as String? ?? '',
            phone: u['phone'] as String?,
            school: sname,
            status: (u['is_active'] as bool? ?? true)
                ? HeadmasterStatus.active
                : HeadmasterStatus.pendingSetup,
          );
        }).toList(),
      );
      if (res.success && res.data != null) out.addAll(res.data!);
    }
    return ApiResponse.ok(out);
  }

  /// Creates a school's headmaster (Super-Admin only).
  Future<ApiResponse<Headmaster>> createHeadmaster(
    String schoolId,
    Map<String, dynamic> payload,
  ) {
    return _api.request<Headmaster>(
      method: HttpMethod.post,
      path: AdminEndpoints.schoolHeadmaster(schoolId),
      body: payload,
      parser: (json) {
        final u = json as Map<String, dynamic>;
        return Headmaster(
          id: '${u['id']}',
          name: u['full_name'] as String? ?? '',
          email: u['email'] as String? ?? '',
          phone: u['phone'] as String?,
          status: HeadmasterStatus.active,
        );
      },
    );
  }
}
