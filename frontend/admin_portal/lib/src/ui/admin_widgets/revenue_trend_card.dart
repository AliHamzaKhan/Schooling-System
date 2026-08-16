import 'package:flutter/material.dart';

import '../../data/models/admin_metrics.dart';
import '../admin_theme.dart';
import 'admin_surface.dart';

/// Monthly-revenue bar chart (used by Billing and Metrics). One bar per
/// [RevenueMonth]; the latest month is picked out in navy with its value in a
/// tooltip above the bar, the rest sit in a neutral wash.
class RevenueTrendCard extends StatelessWidget {
  final String title;
  final List<RevenueMonth> months;

  const RevenueTrendCard({
    super.key,
    required this.title,
    required this.months,
  });

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

  static String money(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AdminType.cardTitle)),
              if (months.isNotEmpty) _RangeLabel(count: months.length),
            ],
          ),
          const SizedBox(height: 22),
          if (months.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text('No revenue recorded yet.', style: AdminType.body),
            )
          else
            SizedBox(height: 190, child: _Bars(months: months)),
        ],
      ),
    );
  }
}

/// Static "Last N Months" caption describing the window the chart covers.
class _RangeLabel extends StatelessWidget {
  final int count;
  const _RangeLabel({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AdminPalette.tint,
          borderRadius: BorderRadius.circular(AdminRadius.chip),
        ),
        child: Text('Last $count Months',
            style: AdminType.meta.copyWith(
                color: AdminPalette.ink, fontWeight: FontWeight.w600)),
      );
}

class _Bars extends StatelessWidget {
  final List<RevenueMonth> months;
  const _Bars({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxV = months.fold<double>(1, (m, r) => r.total > m ? r.total : m);
    final activeIndex = months.length - 1;

    return Column(
      children: [
        // Tooltip lane — reserves a fixed strip so bars stay aligned whichever
        // column is highlighted.
        SizedBox(
          height: 26,
          child: Row(
            children: [
              for (var i = 0; i < months.length; i++) ...[
                Expanded(
                  child: i == activeIndex
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: _Tooltip(
                              value: RevenueTrendCard.money(months[i].total)),
                        )
                      : const SizedBox.shrink(),
                ),
                if (i != months.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++) ...[
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: (months[i].total / maxV).clamp(0.04, 1.0),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 6),
                      decoration: BoxDecoration(
                        color: i == activeIndex
                            ? AdminPalette.ink
                            : AdminPalette.tint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (i != months.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < months.length; i++) ...[
              Expanded(
                child: Text(
                  RevenueTrendCard._short(months[i].month),
                  textAlign: TextAlign.center,
                  style: AdminType.meta.copyWith(
                    fontSize: 12,
                    color: i == activeIndex
                        ? AdminPalette.ink
                        : AdminPalette.faint,
                    fontWeight:
                        i == activeIndex ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (i != months.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

/// Dark value bubble that sits above the highlighted bar.
class _Tooltip extends StatelessWidget {
  final String value;
  const _Tooltip({required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminPalette.ink,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: AdminType.meta.copyWith(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
}
