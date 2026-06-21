import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/overview_data.dart';

/// "Island Pulse" KPI card — accent rail, soft icon tile, label + big value,
/// trend pill in the top-right corner (text or "Stable").
class PulseCard extends StatelessWidget {
  final PulseMetric metric;
  const PulseCard({super.key, required this.metric});

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
                color: metric.accent,
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(metric.icon, color: metric.accent, size: 18),
                        ),
                        const Spacer(),
                        if (metric.trendLabel != null) _TrendPill(metric: metric),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(metric.label, style: AppTypography.bodyLg),
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

class _TrendPill extends StatelessWidget {
  final PulseMetric metric;
  const _TrendPill({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric.trendColor ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (metric.trendIcon != null) ...[
            Icon(metric.trendIcon, size: 13, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Text('=', style: AppTypography.labelMd.copyWith(color: color)),
            const SizedBox(width: 4),
          ],
          Text(metric.trendLabel!,
              style: AppTypography.labelCaps
                  .copyWith(color: color, letterSpacing: 0, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
