import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/status_pill.dart';
import '../models/analytics_data.dart';

/// Compact KPI tile: colored icon square on the left, trend pill on the right,
/// then the label and a bold value beneath.
class AnalyticsMetricCard extends StatelessWidget {
  final AnalyticsMetric metric;

  /// Hidden when there is no trend series to show (avoids a fake 0% pill).
  final bool showTrend;

  const AnalyticsMetricCard({
    super.key,
    required this.metric,
    this.showTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(metric.icon, color: metric.iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label, style: AppTypography.bodyMd),
                const SizedBox(height: 2),
                Text(metric.value,
                    style: AppTypography.headlineLg.copyWith(fontSize: 24)),
              ],
            ),
          ),
          if (showTrend) StatusPill.trend(metric.trendPercent),
        ],
      ),
    );
  }
}
