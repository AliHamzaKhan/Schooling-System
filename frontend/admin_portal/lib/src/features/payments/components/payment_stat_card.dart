import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/payments_data.dart';

/// Payments KPI card: rounded icon tile, label, and a large value, with a
/// color-matched left accent rail.
class PaymentStatCard extends StatelessWidget {
  final PaymentStat stat;
  const PaymentStatCard({super.key, required this.stat});

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
                color: stat.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: stat.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Icon(stat.icon, color: stat.color, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stat.label, style: AppTypography.titleMd),
                          const SizedBox(height: 2),
                          Text(stat.value,
                              style: AppTypography.displayLg.copyWith(fontSize: 28)),
                        ],
                      ),
                    ),
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
