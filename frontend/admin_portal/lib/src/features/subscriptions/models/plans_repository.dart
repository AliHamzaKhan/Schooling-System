import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import 'subscription_models.dart';

/// Data gateway for editable subscription plans (the products admins price).
/// Wraps [AdminApiService] so the controller stays off the network layer.
class PlansRepository {
  PlansRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<List<SubscriptionPlanModel>>> fetch() => _api.fetchPlans();

  Future<ApiResponse<SubscriptionPlanModel>> create({
    required String name,
    required double price,
    required BillingPeriod billingPeriod,
    String? description,
    int? maxStudents,
    int? storageQuotaMb,
    List<String> modules = const [],
  }) =>
      _api.createPlan({
        'name': name,
        'price': price,
        'billing_period': billingPeriod.code,
        'modules': modules,
        if (description != null && description.isNotEmpty)
          'description': description,
        // Sent as null when uncapped so the plan is explicitly unlimited.
        'max_students': maxStudents,
        'storage_quota_mb': storageQuotaMb,
      });

  /// Full update from the plan editor. The editor always carries every field,
  /// so all are sent — including `max_students: null` to mean "unlimited" and
  /// `modules` (the enabled feature keys).
  Future<ApiResponse<SubscriptionPlanModel>> update(
    String id, {
    required String name,
    required double price,
    required BillingPeriod billingPeriod,
    required List<String> modules,
    String? description,
    int? maxStudents,
    int? storageQuotaMb,
  }) {
    return _api.updatePlan(id, {
      'name': name,
      'price': price,
      'billing_period': billingPeriod.code,
      'modules': modules,
      'description': description ?? '',
      'max_students': maxStudents,
      'storage_quota_mb': storageQuotaMb,
    });
  }

  Future<ApiResponse<SubscriptionPlanModel>> archive(String id) =>
      _api.archivePlan(id);
}
