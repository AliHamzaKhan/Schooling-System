import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Simple vertical bar chart with rounded bars and x-axis labels. The last bar
/// can be [highlightLast]-ed in the accent color (the rest sit muted).
class AdminBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;
  final bool highlightLast;

  const AdminBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 160,
    this.color = AppColors.primary,
    this.highlightLast = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor: (values[i] / maxV).clamp(0.04, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: highlightLast && i == values.length - 1
                              ? color
                              : color.withValues(alpha: 0.18),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i != values.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: i == labels.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == labels.length - 1
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (i != labels.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
