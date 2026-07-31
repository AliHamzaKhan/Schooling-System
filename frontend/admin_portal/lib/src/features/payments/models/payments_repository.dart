import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import '../../../data/models/admin_metrics.dart';

/// Loads the Payments & Billing overview from the live `/admin/billing` endpoint.
class PaymentsRepository {
  PaymentsRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<BillingReport>> load() => _api.fetchBilling();
}
