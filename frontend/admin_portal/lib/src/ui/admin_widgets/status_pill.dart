import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Small rounded status/trend chip. Tint the fill + text via [color]; the
/// background is a soft wash of it.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Positive (emerald) / negative (red) trend pill from a signed percent.
  factory StatusPill.trend(double percent) {
    final positive = percent >= 0;
    final sign = positive ? '+' : '';
    return StatusPill(
      label: '$sign${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 1)}%',
      color: positive ? AppColors.tertiary : AppColors.error,
      icon: positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
