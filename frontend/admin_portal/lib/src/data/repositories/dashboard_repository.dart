import 'package:shared/shared.dart';

import '../admin_api_service.dart';
import '../models/dashboard_stats.dart';

/// Loads the admin home KPIs from the live `/admin/dashboard` endpoint and maps
/// them onto the three headline [StatMetric] cards (Total Schools, Active
/// Subscriptions, Monthly Revenue). Trend/sparkline series are not tracked
/// server-side, so the cards render the value only.
class DashboardRepository {
  DashboardRepository({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  Future<ApiResponse<DashboardData>> load() async {
    final res = await _api.fetchDashboard();
    if (!res.success || res.data == null) {
      return ApiResponse.fail(res.error ?? 'Could not load the dashboard.',
          statusCode: res.statusCode);
    }
    final d = res.data!;
    return ApiResponse.ok(DashboardData(
      metrics: [
        StatMetric(
          label: 'Total Schools',
          value: _int(d.totalSchools),
          trendPercent: 0,
        ),
        StatMetric(
          label: 'Active Subscriptions',
          value: _int(d.activeSubscriptions),
          trendPercent: 0,
        ),
        StatMetric(
          label: 'Monthly Revenue',
          value: _money(d.monthlyRevenue),
          trendPercent: 0,
        ),
      ],
      alerts: const [],
    ));
  }

  static String _int(int v) =>
      v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  static String _money(double v) {
    final whole = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$$whole';
  }
}
