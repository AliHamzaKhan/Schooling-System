import 'package:flutter/material.dart';

/// A KPI tile on the Analytics Overview screen.
class AnalyticsMetric {
  final String label;
  final String value;
  final double trendPercent;
  final IconData icon;
  final Color iconColor;

  const AnalyticsMetric({
    required this.label,
    required this.value,
    required this.trendPercent,
    required this.icon,
    required this.iconColor,
  });

  bool get isPositive => trendPercent >= 0;
}

/// A breakdown row in the subscriptions donut legend.
class SubscriptionShare {
  final String label;
  final int percent;
  final Color color;
  const SubscriptionShare({required this.label, required this.percent, required this.color});
}

/// Everything the Analytics Overview screen renders.
class AnalyticsData {
  final List<AnalyticsMetric> metrics;
  final List<double> students;
  final List<double> educators;
  final List<String> months;
  final String totalActive;
  final List<SubscriptionShare> subscriptionShares;
  final List<double> revenueByMonth;

  const AnalyticsData({
    required this.metrics,
    required this.students,
    required this.educators,
    required this.months,
    required this.totalActive,
    required this.subscriptionShares,
    required this.revenueByMonth,
  });
}
