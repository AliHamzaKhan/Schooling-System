/// Top-of-dashboard KPI cards + the alerts feed shown on the admin home.
library;

/// One headline KPI card (Total Schools, Active Subscriptions, …).
class StatMetric {
  final String label;
  final String value;

  /// Percent change vs. previous period (e.g. `12` or `-1.4`).
  final double trendPercent;

  /// Tiny sparkline bars under the value (relative heights, 0..1 not required).
  final List<double> spark;

  const StatMetric({
    required this.label,
    required this.value,
    required this.trendPercent,
    this.spark = const [],
  });

  bool get isPositive => trendPercent >= 0;

  factory StatMetric.fromJson(Map<String, dynamic> j) => StatMetric(
        label: j['label'] as String,
        value: j['value'] as String,
        trendPercent: (j['trendPercent'] as num).toDouble(),
        spark: (j['spark'] as List? ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

enum AlertSeverity { critical, warning, info }

/// A row in the "Recent Alerts" feed.
class AdminAlert {
  final String title;
  final String body;
  final String timeAgo;
  final AlertSeverity severity;

  const AdminAlert({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.severity,
  });

  factory AdminAlert.fromJson(Map<String, dynamic> j) => AdminAlert(
        title: j['title'] as String,
        body: j['body'] as String,
        timeAgo: j['timeAgo'] as String,
        severity: AlertSeverity.values.byName(j['severity'] as String? ?? 'info'),
      );
}

/// Aggregate payload for the dashboard screen.
class DashboardData {
  final List<StatMetric> metrics;
  final List<AdminAlert> alerts;

  const DashboardData({required this.metrics, required this.alerts});
}
