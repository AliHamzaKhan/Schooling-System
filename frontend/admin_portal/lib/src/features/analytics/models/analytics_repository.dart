import 'package:shared/shared.dart';

import '../../../data/admin_api_service.dart';
import '../../../data/models/admin_metrics.dart';

/// Loads the platform metrics (`/admin/metrics`) for the Analytics screen.
class AnalyticsRepository {
  AnalyticsRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<MetricsReport>> load() => _api.fetchMetrics();
}
