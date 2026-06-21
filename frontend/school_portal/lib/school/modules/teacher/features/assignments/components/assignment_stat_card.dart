import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Wide KPI card with a label, big value, trend caption, and a soft circular
/// icon badge on the right.
class AssignmentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color accent;
  final Color trendColor;

  const AssignmentStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.accent,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackLg, vertical: AppSpacing.stackLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyLg),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTypography.displayLg.copyWith(fontSize: 38)),
                const SizedBox(height: 2),
                Text(trend,
                    style: AppTypography.bodyMd
                        .copyWith(color: trendColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
        ],
      ),
    );
  }
}
