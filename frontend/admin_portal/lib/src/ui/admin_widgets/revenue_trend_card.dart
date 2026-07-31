import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/models/admin_metrics.dart';

/// Reusable monthly-revenue bar chart (used by Billing and Metrics). Renders one
/// bar per [RevenueMonth], labelled by short month, with the value above the
/// tallest bar. Purely presentational — pass in live buckets.
class RevenueTrendCard extends StatelessWidget {
  final String title;
  final List<RevenueMonth> months;
  const RevenueTrendCard({super.key, required this.title, required this.months});

  static String _short(String ym) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final mi = int.tryParse(parts[1]) ?? 0;
    return (mi >= 1 && mi <= 12) ? names[mi - 1] : ym;
  }

  static String _money(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headlineLg.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.stackLg),
          if (months.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
              child: Text('No revenue recorded yet.',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
            )
          else
            SizedBox(height: 170, child: _Bars(months: months)),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  final List<RevenueMonth> months;
  const _Bars({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxV = months.fold<double>(1, (m, r) => r.total > m ? r.total : m);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++) ...[
                Expanded(child: _bar(months[i], maxV)),
                if (i != months.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < months.length; i++) ...[
              Expanded(
                child: Text(RevenueTrendCard._short(months[i].month),
                    textAlign: TextAlign.center, style: AppTypography.bodySm),
              ),
              if (i != months.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bar(RevenueMonth m, double maxV) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(RevenueTrendCard._money(m.total),
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
        const SizedBox(height: 4),
        FractionallySizedBox(
          heightFactor: (m.total / maxV).clamp(0.03, 1.0),
          child: Container(
            constraints: const BoxConstraints(minHeight: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, Color(0xFFAFC4F5)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
            ),
          ),
        ),
      ],
    );
  }
}
