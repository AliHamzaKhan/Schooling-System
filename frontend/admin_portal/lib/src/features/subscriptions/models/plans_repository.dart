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
  }) =>
      _api.createPlan({
        'name': name,
        'price': price,
        'billing_period': billingPeriod.code,
        if (description != null && description.isNotEmpty)
          'description': description,
      });

  Future<ApiResponse<SubscriptionPlanModel>> update(
    String id, {
    String? name,
    double? price,
    BillingPeriod? billingPeriod,
    String? description,
  }) {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (price != null) payload['price'] = price;
    if (billingPeriod != null) payload['billing_period'] = billingPeriod.code;
    if (description != null) payload['description'] = description;
    return _api.updatePlan(id, payload);
  }

  Future<ApiResponse<SubscriptionPlanModel>> archive(String id) =>
      _api.archivePlan(id);
}
