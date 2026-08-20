import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/status_pill.dart';
import '../models/dashboard_data.dart';

/// Dashboard KPI card: compact tile with icon, label, big value, trend pill,
/// and an optional "+ create" affordance in the top-right. Tapping the card
/// navigates to the listing; tapping the "+" opens the create flow.
class DashboardMetricCard extends StatelessWidget {
  final DashboardMetric metric;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const DashboardMetricCard({
    super.key,
    required this.metric,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  if (onAdd != null)
                    InkResponse(
                      onTap: onAdd,
                      radius: 20,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: metric.color,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Icon(AppIcons.add,
                            size: 18, color: Colors.white),
                      ),
                    )
                  else if (metric.hasTrend)
                    StatusPill.trend(metric.trendPercent),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(metric.label,
                  style: AppTypography.bodyMd,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(metric.value,
                  style: AppTypography.displayLg.copyWith(fontSize: 28)),
              if (metric.hasTrend && onAdd != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                StatusPill.trend(metric.trendPercent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
