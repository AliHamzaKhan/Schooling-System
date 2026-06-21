import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';

/// Pill badge with optional leading icon — used for onboarding step indicators
/// (e.g. "STEP 3: CARE ANYWHERE", "AI-POWERED INSIGHTS").
class StepBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? tint;

  const StepBadge({
    super.key,
    required this.label,
    this.icon,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
