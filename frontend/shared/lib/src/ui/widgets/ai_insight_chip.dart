import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_typography.dart';
import 'package:shared/shared.dart';

/// Pill-shaped chip with subtle purple glow — for AI/predictive content only.
///
/// Per DESIGN.md: "AI Insight Chips ... Subtle Purple glow effect
/// (box-shadow: 0 0 12px rgba(126, 87, 194, 0.3))".
class AIInsightChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const AIInsightChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.aiAccent.withValues(alpha: 0.35), width: 1),
        boxShadow: AppElevation.aiGlow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? AppIcons.autoAwesome, size: 14, color: AppColors.aiAccent),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(color: AppColors.aiAccent),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: content,
    );
  }
}
