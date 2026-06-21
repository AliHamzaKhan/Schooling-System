import 'package:shared/shared.dart';

import '../models/dashboard_stats.dart';

/// Loads dashboard KPIs + alerts.
///
/// Returns the same [ApiResponse] envelope the real API will use, so swapping
/// the mock body for an `ApiService.request` call later touches only this file.
class DashboardRepository {
  // final ApiService _api = Get.find<ApiService>();

  Future<ApiResponse<DashboardData>> load() async {
    // TODO: replace with `_api.request(method: HttpMethod.get, path: '/admin/dashboard')`.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return ApiResponse.ok(_mock);
  }

  static const _mock = DashboardData(
    metrics: [
      StatMetric(
        label: 'Total Schools',
        value: '1,284',
        trendPercent: 12,
        spark: [3, 4, 3.5, 4, 3.8, 6, 7],
      ),
      StatMetric(
        label: 'Active Subscriptions',
        value: '84.5k',
        trendPercent: 5.2,
        spark: [2, 2.4, 2.2, 2.6, 4, 4.6, 5],
      ),
      StatMetric(
        label: 'Monthly Revenue',
        value: '\$2.4M',
        trendPercent: -1.4,
        spark: [4, 3.6, 3.8, 3.4, 3.2, 4.2, 4.6],
      ),
    ],
    alerts: [
      AdminAlert(
        title: 'Payment Gateway Sync Failure',
        body:
            'Stripe integration experienced a timeout for 45 seconds. 12 transactions queued.',
        timeAgo: '10m ago',
        severity: AlertSeverity.critical,
      ),
      AdminAlert(
        title: 'System Maintenance Scheduled',
        body:
            'Database optimization planned for 02:00 UTC. Expect 15 mins downtime.',
        timeAgo: '2h ago',
        severity: AlertSeverity.warning,
      ),
      AdminAlert(
        title: 'New District Onboarded',
        body: 'Oakridge School District has completed their setup phase.',
        timeAgo: '5h ago',
        severity: AlertSeverity.info,
      ),
    ],
  );
}
