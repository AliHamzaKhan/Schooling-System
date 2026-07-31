import 'package:flutter/material.dart';

/// A KPI tile on the System Metrics screen.
class AnalyticsMetric {
  final String label;
  final String value;
  final double trendPercent;
  final IconData icon;
  final Color iconColor;

  const AnalyticsMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trendPercent = 0,
  });

  bool get isPositive => trendPercent >= 0;
}
