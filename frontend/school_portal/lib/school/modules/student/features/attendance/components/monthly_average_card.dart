import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/attendance_data.dart';

// Shared status palette for the attendance screen.
const kAttendPresent = Color(0xFF059669);
const kAttendLate = Color(0xFFE8A317);
const kAttendAbsent = Color(0xFFDC2626);

/// Monthly-average card: a circular progress **ring** with the percent inside,
/// the month label, and the change vs. last month.
class AttendanceRingCard extends StatelessWidget {
  final int percent;
  final int delta;

  /// Defaults to the current month/year when omitted.
  final String? monthLabel;

  const AttendanceRingCard({
    super.key,
    required this.percent,
    required this.delta,
    this.monthLabel,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    final now = DateTime.now();
    final label = monthLabel ?? '${_months[now.month - 1]} ${now.year}';
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        children: [
          Text('MONTHLY AVERAGE',
              style: AppTypography.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _RingPainter(value: (percent / 100).clamp(0.0, 1.0)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$percent%',
                        style: AppTypography.displayLg
                            .copyWith(fontSize: 46, color: AppColors.primary)),
                    Text('Present',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(up ? AppIcons.trendingUpRounded : AppIcons.trendingDownRounded,
                  size: 16, color: up ? kAttendPresent : kAttendAbsent),
              const SizedBox(width: 6),
              Text('${up ? '+' : ''}$delta% from last month',
                  style: AppTypography.bodyMd),
              Text('   ·   $label',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.surfaceContainerHigh,
    );

    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      value * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = SweepGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.70),
            AppColors.primary,
          ],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}

/// Weekly-status card: a multi-line chart tracking Present / Late / Absent
/// across the week, with a legend. Each day carries exactly one status, so the
/// three series are drawn as **cumulative counts** — they stay separated and
/// read as a real trend ("by Friday: 4 present, 1 late, 0 absent").
class WeeklyStatusCard extends StatelessWidget {
  final List<DayBar> week;
  const WeeklyStatusCard({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final present = <FlSpot>[];
    final late = <FlSpot>[];
    final absent = <FlSpot>[];
    var p = 0.0, l = 0.0, a = 0.0;
    for (var i = 0; i < week.length; i++) {
      final r = week[i].presentRatio;
      if (r >= 1) {
        p += 1;
      } else if (r > 0) {
        l += 1;
      } else {
        a += 1;
      }
      present.add(FlSpot(i.toDouble(), p));
      late.add(FlSpot(i.toDouble(), l));
      absent.add(FlSpot(i.toDouble(), a));
    }
    final maxY = math.max(1.0, [p, l, a].reduce(math.max));

    LineChartBarData bar(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, barData, index) => FlDotCirclePainter(
              radius: 3,
              color: color,
              strokeWidth: 1.5,
              strokeColor: AppColors.surfaceContainerLowest,
            ),
          ),
        );

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Status',
              style: AppTypography.headlineLg.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            height: 150,
            child: week.isEmpty
                ? Center(
                    child: Text('No attendance recorded this week.',
                        style: AppTypography.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant)),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (week.length - 1).toDouble().clamp(0, double.infinity),
                      minY: 0,
                      maxY: maxY + 0.4,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: math.max(1, (maxY / 3).ceilToDouble()),
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= week.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(week[i].label,
                                    style: AppTypography.bodySm),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        bar(absent, kAttendAbsent),
                        bar(late, kAttendLate),
                        bar(present, kAttendPresent),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: kAttendPresent, label: 'Present'),
              SizedBox(width: AppSpacing.stackLg),
              _LegendDot(color: kAttendLate, label: 'Late'),
              SizedBox(width: AppSpacing.stackLg),
              _LegendDot(color: kAttendAbsent, label: 'Absent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySm),
      ],
    );
  }
}
