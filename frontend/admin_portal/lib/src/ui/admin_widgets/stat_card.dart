import 'package:flutter/material.dart';

import '../../data/models/dashboard_stats.dart';
import '../admin_theme.dart';
import 'admin_surface.dart';
import 'status_pill.dart';

/// Dashboard KPI card: label + big value on the left, an icon chip on the
/// right, and an optional trend pill / sparkline underneath.
class StatCard extends StatelessWidget {
  final StatMetric metric;

  /// Glyph for the icon chip.
  final IconData icon;

  /// When true the chip inverts to solid navy — used for the lead KPI.
  final bool emphasized;

  /// When set, the whole card is tappable (e.g. drill into schools / revenue).
  final VoidCallback? onTap;

  /// Whether to show the trend pill. Hidden when no trend data is tracked.
  final bool showTrend;

  const StatCard({
    super.key,
    required this.metric,
    required this.icon,
    this.emphasized = false,
    this.onTap,
    this.showTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      color: emphasized ? AdminPalette.tint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.label,
                        style: AdminType.body.copyWith(
                            fontSize: 14.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(metric.value,
                              style: AdminType.metric,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (showTrend) ...[
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: StatusPill.trend(metric.trendPercent),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AdminIconTile(
                icon: icon,
                size: 42,
                background: emphasized ? AdminPalette.ink : AdminPalette.tint,
                foreground: emphasized ? Colors.white : AdminPalette.ink,
              ),
            ],
          ),
          if (metric.spark.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MiniBars(values: metric.spark),
          ],
        ],
      ),
    );
  }
}

/// Row of rounded bars; the last two use the navy ink, the rest sit in the
/// lavender wash.
class _MiniBars extends StatelessWidget {
  final List<double> values;
  const _MiniBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Expanded(
              child: Container(
                height: maxV == 0 ? 3 : ((values[i] / maxV) * 30).clamp(3, 30),
                decoration: BoxDecoration(
                  color: i >= values.length - 2
                      ? AdminPalette.ink
                      : AdminPalette.tint,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
