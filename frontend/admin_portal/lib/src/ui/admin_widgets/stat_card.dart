import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/models/dashboard_stats.dart';
import 'status_pill.dart';

/// KPI card: colored left accent rail, label, big value, a trend pill, and a
/// row of mini sparkline bars (the last two bars tinted with the accent).
class StatCard extends StatelessWidget {
  final StatMetric metric;
  final Color accent;

  const StatCard({super.key, required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.l1,
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.card,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent rail.
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.label, style: AppTypography.bodyMd),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            metric.value,
                            style: AppTypography.displayLg.copyWith(fontSize: 30),
                          ),
                        ),
                        StatusPill.trend(metric.trendPercent),
                      ],
                    ),
                    if (metric.spark.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.stackMd),
                      _MiniBars(values: metric.spark, accent: accent),
                    ],
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

/// Row of rounded bars; the two tallest-position (last) bars use [accent],
/// the rest sit in a neutral wash — matching the dashboard mock.
class _MiniBars extends StatelessWidget {
  final List<double> values;
  final Color accent;
  const _MiniBars({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Expanded(
              child: Container(
                height: (values[i] / maxV) * 34,
                decoration: BoxDecoration(
                  color: i >= values.length - 2
                      ? accent
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
