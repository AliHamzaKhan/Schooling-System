import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/status_pill.dart';
import '../models/dashboard_data.dart';

/// Dashboard KPI card: colored left rail, icon tile, label + big value, and a
/// trend pill in the top-right corner.
class DashboardMetricCard extends StatelessWidget {
  final DashboardMetric metric;
  const DashboardMetricCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: metric.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: metric.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          child: Icon(metric.icon, color: metric.color, size: 22),
                        ),
                        const Spacer(),
                        if (metric.hasTrend) StatusPill.trend(metric.trendPercent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(metric.label, style: AppTypography.bodyMd),
                    const SizedBox(height: 2),
                    Text(metric.value,
                        style: AppTypography.displayLg.copyWith(fontSize: 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
