import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Top-of-screen KPI tile with a colored sparkline bar row beneath the value.
class ReportMetric {
  final String label;
  final String value;
  final double trendPercent;
  final IconData icon;
  final Color color;
  final List<double> spark;

  const ReportMetric({
    required this.label,
    required this.value,
    required this.trendPercent,
    required this.icon,
    required this.color,
    required this.spark,
  });

  factory ReportMetric.fromJson(Map<String, dynamic> json) => ReportMetric(
        label: json['label'] as String? ?? '',
        value: '${json['value'] ?? ''}',
        trendPercent: (json['trend_percent'] as num?)?.toDouble() ?? 0,
        // icon/color are presentation only — defaulted, not from the API.
        icon: Icons.insights_rounded,
        color: AppColors.primary,
        spark: ((json['spark'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

enum PerformanceRange { term, year }

/// Aggregate Reports & Analytics payload.
class ReportsData {
  final List<ReportMetric> metrics;

  /// Two series for the academic performance chart (Q1..Q4).
  final List<double> currentYearScores;
  final List<double> previousYearScores;
  final List<String> performanceLabels;

  /// Enrollment Distribution bars (Y7..Y11 etc.).
  final Map<String, int> enrollmentByYear;

  const ReportsData({
    required this.metrics,
    required this.currentYearScores,
    required this.previousYearScores,
    required this.performanceLabels,
    required this.enrollmentByYear,
  });

  factory ReportsData.fromJson(Map<String, dynamic> json) => ReportsData(
        metrics: ((json['metrics'] as List?) ?? [])
            .map((e) => ReportMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentYearScores: ((json['current_year_scores'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        previousYearScores: ((json['previous_year_scores'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        performanceLabels: ((json['performance_labels'] as List?) ?? [])
            .map((e) => '$e')
            .toList(),
        enrollmentByYear:
            ((json['enrollment_by_year'] as Map?) ?? const {}).map(
          (k, v) => MapEntry('$k', (v as num).toInt()),
        ),
      );
}
