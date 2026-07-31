import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../features/headmasters/models/headmaster.dart';
import '../features/schools/models/school.dart';
import '../features/subscriptions/models/subscription_models.dart';
import 'admin_endpoints.dart';
import 'models/admin_metrics.dart';

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
            schoolId: sid,
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
          schoolId: schoolId,
          status: HeadmasterStatus.active,
        );
      },
    );
  }

  Headmaster _headmasterFromUser(Map<String, dynamic> u, String schoolId) =>
      Headmaster(
        id: '${u['id']}',
        name: u['full_name'] as String? ?? '',
        email: u['email'] as String? ?? '',
        phone: u['phone'] as String?,
        schoolId: schoolId,
        status: (u['is_active'] as bool? ?? true)
            ? HeadmasterStatus.active
            : HeadmasterStatus.pendingSetup,
      );

  /// Updates a user (`full_name` / `phone`). Used to edit a headmaster.
  Future<ApiResponse<Headmaster>> updateUser(
    String schoolId,
    String userId,
    Map<String, dynamic> payload,
  ) {
    return _api.request<Headmaster>(
      method: HttpMethod.patch,
      path: '${AdminEndpoints.schoolUsers(schoolId)}/$userId',
      body: payload,
      parser: (json) => _headmasterFromUser(json as Map<String, dynamic>, schoolId),
    );
  }

  /// Deactivates a user (the backend has no hard delete) → soft "delete".
  Future<ApiResponse<Headmaster>> deactivateUser(String schoolId, String userId) {
    return _api.request<Headmaster>(
      method: HttpMethod.post,
      path: '${AdminEndpoints.schoolUsers(schoolId)}/$userId/deactivate',
      parser: (json) => _headmasterFromUser(json as Map<String, dynamic>, schoolId),
    );
  }

  // ── Platform metrics ────────────────────────────────────────
  /// Live KPIs for the admin Dashboard (total schools, active subs, revenue).
  Future<ApiResponse<AdminDashboardData>> fetchDashboard() {
    return _api.request<AdminDashboardData>(
      method: HttpMethod.get,
      path: AdminEndpoints.adminDashboard,
      parser: (json) => AdminDashboardData.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Revenue grouped by calendar month (oldest → newest).
  Future<ApiResponse<RevenueReport>> fetchRevenue({int months = 12}) {
    return _api.request<RevenueReport>(
      method: HttpMethod.get,
      path: AdminEndpoints.adminRevenue,
      query: {'months': '$months'},
      parser: (json) => RevenueReport.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Billing overview: totals, pending, recent payments, revenue trend.
  Future<ApiResponse<BillingReport>> fetchBilling() {
    return _api.request<BillingReport>(
      method: HttpMethod.get,
      path: AdminEndpoints.adminBilling,
      parser: (json) => BillingReport.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Platform metrics: KPIs, churn, plan distribution, revenue trend.
  Future<ApiResponse<MetricsReport>> fetchMetrics() {
    return _api.request<MetricsReport>(
      method: HttpMethod.get,
      path: AdminEndpoints.adminMetrics,
      parser: (json) => MetricsReport.fromJson(json as Map<String, dynamic>),
    );
  }

  // ── Subscription plans (editable products) ──────────────────
  Future<ApiResponse<List<SubscriptionPlanModel>>> fetchPlans({
    bool includeArchived = false,
  }) {
    return _api.request<List<SubscriptionPlanModel>>(
      method: HttpMethod.get,
      path: AdminEndpoints.subscriptionPlans,
      query: {'include_archived': '$includeArchived'},
      parser: (json) => (json as List)
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<SubscriptionPlanModel>> createPlan(
    Map<String, dynamic> payload,
  ) {
    return _api.request<SubscriptionPlanModel>(
      method: HttpMethod.post,
      path: AdminEndpoints.subscriptionPlans,
      body: payload,
      parser: (json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SubscriptionPlanModel>> updatePlan(
    String id,
    Map<String, dynamic> payload,
  ) {
    return _api.request<SubscriptionPlanModel>(
      method: HttpMethod.patch,
      path: AdminEndpoints.subscriptionPlan(id),
      body: payload,
      parser: (json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Archives (soft-deletes) a plan.
  Future<ApiResponse<SubscriptionPlanModel>> archivePlan(String id) {
    return _api.request<SubscriptionPlanModel>(
      method: HttpMethod.delete,
      path: AdminEndpoints.subscriptionPlan(id),
      parser: (json) => SubscriptionPlanModel.fromJson(json as Map<String, dynamic>),
    );
  }

  // ── Subscription instances (per-school) ─────────────────────
  /// `statusFilter` = all | active | pending | history.
  Future<ApiResponse<List<SchoolSubscriptionModel>>> fetchSubscriptions({
    String statusFilter = 'all',
  }) {
    return _api.request<List<SchoolSubscriptionModel>>(
      method: HttpMethod.get,
      path: AdminEndpoints.subscriptions,
      query: {'status_filter': statusFilter},
      parser: (json) => (json as List)
          .map((e) => SchoolSubscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Assigns a plan to a school with an optional discount, creating the
  /// subscription instance + initial payment.
  Future<ApiResponse<SchoolSubscriptionModel>> assignSubscriptionInstance({
    required String schoolId,
    required String planId,
    String discountType = 'none',
    double discountValue = 0,
    bool activate = true,
  }) {
    return _api.request<SchoolSubscriptionModel>(
      method: HttpMethod.post,
      path: AdminEndpoints.subscriptions,
      body: {
        'school_id': schoolId,
        'plan_id': planId,
        'discount_type': discountType,
        'discount_value': discountValue,
        'activate': activate,
      },
      parser: (json) => SchoolSubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SchoolSubscriptionModel>> renewSubscription(String id) {
    return _api.request<SchoolSubscriptionModel>(
      method: HttpMethod.post,
      path: AdminEndpoints.subscriptionRenew(id),
      body: const {},
      parser: (json) => SchoolSubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<SchoolSubscriptionModel>> cancelSubscription(String id) {
    return _api.request<SchoolSubscriptionModel>(
      method: HttpMethod.post,
      path: AdminEndpoints.subscriptionCancel(id),
      parser: (json) => SchoolSubscriptionModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
