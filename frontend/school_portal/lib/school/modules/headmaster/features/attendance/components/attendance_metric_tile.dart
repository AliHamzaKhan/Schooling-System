import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/status_pill.dart';
import '../models/attendance_data.dart';

/// Attendance KPI row with a colored left rail, square icon tile, label,
/// big value, and a trend pill on the right.
class AttendanceMetricTile extends StatelessWidget {
  final AttendanceMetric metric;
  const AttendanceMetricTile({super.key, required this.metric});

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
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(metric.label,
                              style: AppTypography.labelCaps
                                  .copyWith(color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(metric.value,
                              style: AppTypography.headlineLg.copyWith(fontSize: 26)),
                        ],
                      ),
                    ),
                    StatusPill.trend(metric.trendPercent),
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
