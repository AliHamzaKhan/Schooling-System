import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/status_pill.dart';
import '../models/reports_data.dart';

/// Report KPI card with a colored left rail, icon tile + trend pill on top,
/// label + big value, and a row of tinted sparkline bars beneath.
class ReportMetricCard extends StatelessWidget {
  final ReportMetric metric;
  const ReportMetricCard({super.key, required this.metric});

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
                        StatusPill.trend(metric.trendPercent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(metric.label,
                        style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(metric.value,
                        style: AppTypography.displayLg.copyWith(fontSize: 32)),
                    const SizedBox(height: AppSpacing.stackMd),
                    _SparkBars(values: metric.spark, color: metric.color),
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

class _SparkBars extends StatelessWidget {
  final List<double> values;
  final Color color;
  const _SparkBars({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Expanded(
              child: Container(
                height: (values[i] / maxV) * 24,
                decoration: BoxDecoration(
                  color: i == values.length - 1
                      ? color
                      : color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
