import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/admin_metrics.dart';
import '../admin_theme.dart';
import 'admin_surface.dart';

/// Monthly-revenue line chart (used by Billing and Metrics). One point per
/// [RevenueMonth], drawn as a smooth navy line with a soft area fill; touch a
/// point to see its value.
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
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
    final lastIndex = months.length - 1;
    final spots = [
      for (var i = 0; i < months.length; i++)
        FlSpot(i.toDouble(), months[i].total),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (months.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: maxV * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxV / 3 <= 0 ? 1 : maxV / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AdminPalette.border.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    RevenueTrendCard._short(months[i].month),
                    style: AdminType.meta.copyWith(
                      fontSize: 12,
                      color: i == lastIndex
                          ? AdminPalette.ink
                          : AdminPalette.faint,
                      fontWeight:
                          i == lastIndex ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => [
              for (final s in touchedSpots)
                LineTooltipItem(
                  RevenueTrendCard.money(s.y),
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            color: AdminPalette.ink,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: index == lastIndex ? 4 : 3,
                color: AdminPalette.ink,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AdminPalette.ink.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
