import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Compact KPI tile sized to sit three-across in a row.
///
/// Tappable: each stat routes somewhere that acts on it (the grading queue,
/// the assignment list, class performance), with a chevron so the affordance
/// is visible rather than guessed at.
class AssignmentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color accent;
  final Color trendColor;
  final VoidCallback? onTap;

  const AssignmentStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.accent,
    required this.trendColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppTypography.displayLg.copyWith(fontSize: 26)),
          ),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm),
          const SizedBox(height: 2),
          Text(trend,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd
                  .copyWith(color: trendColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
