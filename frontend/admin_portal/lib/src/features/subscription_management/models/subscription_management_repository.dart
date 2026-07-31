import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import '../../subscriptions/models/subscription_models.dart';

/// Data gateway for per-school subscription instances (the All / Active /
/// Pending / History tabs). Wraps [AdminApiService] so the controller never
/// touches the network layer directly.
class SubscriptionManagementRepository {
  SubscriptionManagementRepository({AdminApiService? api})
      : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<List<SchoolSubscriptionModel>>> fetch(String statusFilter) =>
      _api.fetchSubscriptions(statusFilter: statusFilter);

  Future<ApiResponse<SchoolSubscriptionModel>> renew(String id) =>
      _api.renewSubscription(id);

  Future<ApiResponse<SchoolSubscriptionModel>> cancel(String id) =>
      _api.cancelSubscription(id);
}
