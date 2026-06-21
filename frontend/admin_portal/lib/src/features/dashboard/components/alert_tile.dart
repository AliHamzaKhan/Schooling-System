import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../data/models/dashboard_stats.dart';

/// One row in the Recent Alerts feed — leading severity icon, title + body,
/// and a time stamp. Critical alerts get a soft red wash.
class AlertTile extends StatelessWidget {
  final AdminAlert alert;
  const AlertTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final (color, icon, washed) = switch (alert.severity) {
      AlertSeverity.critical => (AppColors.error, Icons.warning_amber_rounded, true),
      AlertSeverity.warning => (const Color(0xFFE8A317), Icons.schedule_rounded, false),
      AlertSeverity.info => (AppColors.primary, Icons.group_add_rounded, false),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: washed
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(alert.title,
                          style: AppTypography.titleMd
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(alert.timeAgo, style: AppTypography.bodySm),
                  ],
                ),
                const SizedBox(height: 4),
                Text(alert.body, style: AppTypography.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
