import 'package:flutter/material.dart';

import '../admin_theme.dart';

/// Small rounded status/trend chip. Tint the text via [color]; the background
/// is a soft wash of it, or an explicit [background].
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;

  /// Draws a filled dot instead of an [icon] — the default status treatment.
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
    this.icon,
    this.dot = false,
  });

  /// Positive (green) / negative (red) trend pill from a signed percent.
  factory StatusPill.trend(double percent) {
    final positive = percent >= 0;
    final sign = positive ? '+' : '';
    final color = positive ? AdminPalette.positive : AdminPalette.danger;
    return StatusPill(
      label:
          '$sign${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 1)}%',
      color: color,
      background:
          positive ? AdminPalette.positiveSoft : AdminPalette.dangerSoft,
      icon: positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AdminRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AdminType.meta.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
