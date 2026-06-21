import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/attendance_data.dart';

/// "Monthly Average" card: emerald percent headline, +x% from last month line,
/// then a 5-bar weekday chart. Bars below 1.0 render with an amber "late"
/// segment on top.
class MonthlyAverageCard extends StatelessWidget {
  final int percent;
  final int delta;
  final List<DayBar> week;
  const MonthlyAverageCard({
    super.key,
    required this.percent,
    required this.delta,
    required this.week,
  });

  static const _emerald = Color(0xFF064E3B);
  static const _amber = Color(0xFFE8A317);

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        children: [
          Text('MONTHLY AVERAGE',
              style: AppTypography.labelCaps
                  .copyWith(color: _emerald, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$percent%',
              style: AppTypography.displayLg
                  .copyWith(fontSize: 64, color: _emerald)),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 14, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Text('+$delta% from last month', style: AppTypography.bodyLg),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            height: 130,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in week)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _Bar(ratio: d.presentRatio),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in week)
                      Expanded(
                        child: Text(d.label,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double ratio;
  const _Bar({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final isPartial = ratio < 1.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPartial)
          Expanded(
            flex: ((1 - ratio) * 100).round().clamp(1, 100000),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDE3CD),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm)),
              ),
            ),
          ),
        Expanded(
          flex: (ratio * 100).round().clamp(1, 100000),
          child: Container(
            decoration: BoxDecoration(
              color: isPartial
                  ? MonthlyAverageCard._amber
                  : MonthlyAverageCard._emerald,
              borderRadius: isPartial
                  ? null
                  : const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
            ),
          ),
        ),
      ],
    );
  }
}
