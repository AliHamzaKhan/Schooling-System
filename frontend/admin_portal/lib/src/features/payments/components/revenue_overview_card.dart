import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/payments_data.dart';

/// Revenue Overview card: a legend (Subscriptions / Add-ons) over stacked bars,
/// one stack per month.
class RevenueOverviewCard extends StatelessWidget {
  final List<RevenueMonth> revenue;
  const RevenueOverviewCard({super.key, required this.revenue});

  static const _subColor = AppColors.primary;
  static const _addColor = Color(0xFFAFC4F5);

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Revenue\nOverview',
                    style: AppTypography.headlineLg.copyWith(fontSize: 24)),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Legend(color: _subColor, label: 'Subscriptions'),
                  SizedBox(height: 6),
                  _Legend(color: _addColor, label: 'Add-ons'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            height: 160,
            child: _StackedBars(revenue: revenue, subColor: _subColor, addColor: _addColor),
          ),
        ],
      ),
    );
  }
}

class _StackedBars extends StatelessWidget {
  final List<RevenueMonth> revenue;
  final Color subColor;
  final Color addColor;
  const _StackedBars({required this.revenue, required this.subColor, required this.addColor});

  @override
  Widget build(BuildContext context) {
    final maxV = revenue.fold<double>(1, (m, r) => r.total > m ? r.total : m);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < revenue.length; i++) ...[
                Expanded(child: _bar(revenue[i], maxV)),
                if (i != revenue.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < revenue.length; i++) ...[
              Expanded(
                child: Text(revenue[i].month,
                    textAlign: TextAlign.center, style: AppTypography.bodySm),
              ),
              if (i != revenue.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bar(RevenueMonth r, double maxV) {
    return FractionallySizedBox(
      heightFactor: (r.total / maxV).clamp(0.04, 1.0),
      child: Column(
        children: [
          Expanded(
            flex: (r.addOns * 100).round().clamp(1, 100000),
            child: Container(
              decoration: BoxDecoration(
                color: addColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
              ),
            ),
          ),
          Expanded(
            flex: (r.subscriptions * 100).round().clamp(1, 100000),
            child: Container(color: subColor),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodyMd),
      ],
    );
  }
}
