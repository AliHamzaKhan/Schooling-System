import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/models/admin_metrics.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/donut_chart.dart';
import '../../../ui/admin_widgets/revenue_trend_card.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../components/analytics_metric_card.dart';
import '../controller/analytics_controller.dart';
import '../models/analytics_data.dart';
import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';

/// System Metrics — live platform KPIs, plan distribution, and revenue trend.
class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  /// Palette cycled across plan-distribution slices.
  static const _palette = [
    AdminPalette.ink,
    AdminPalette.info,
    AdminPalette.warning,
    AdminPalette.positive,
    AdminPalette.info,
  ];

  static String _money(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  List<AnalyticsMetric> _tiles(MetricsReport d) => [
        AnalyticsMetric(
          label: 'Total Schools',
          value: '${d.totalSchools}',
          icon: Icons.apartment_rounded,
          iconColor: AdminPalette.ink,
        ),
        AnalyticsMetric(
          label: 'Active Subscriptions',
          value: '${d.activeSubscriptions}',
          icon: Icons.verified_rounded,
          iconColor: AdminPalette.positive,
        ),
        AnalyticsMetric(
          label: 'Total Users',
          value: '${d.totalUsers}',
          icon: Icons.groups_rounded,
          iconColor: AdminPalette.info,
        ),
        AnalyticsMetric(
          label: 'Monthly Revenue',
          value: _money(d.monthlyRevenue),
          icon: Icons.trending_up_rounded,
          iconColor: AdminPalette.warning,
        ),
        AnalyticsMetric(
          label: 'Churn Rate',
          value: '${d.churnRate}%',
          icon: Icons.sell_rounded,
          iconColor: AdminPalette.danger,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminTopBar(title: 'Metrics', showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AdminType.body));
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('System\nMetrics', style: AdminType.screenTitle),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Live platform performance across all schools.',
                      style: AdminType.body),
                  const SizedBox(height: AppSpacing.stackLg),

                  // KPI tiles (no trend series → no trend pill).
                  for (final m in _tiles(data)) ...[
                    AnalyticsMetricCard(metric: m, showTrend: false),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                  const SizedBox(height: AppSpacing.stackSm),

                  // Plan distribution donut.
                  AdminCard(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Plan Distribution'),
                        const SizedBox(height: 2),
                        Text('Active subscriptions by plan',
                            style: AdminType.meta),
                        const SizedBox(height: AppSpacing.stackLg),
                        if (data.planDistribution.isEmpty)
                          Text('No active subscriptions yet.',
                              style: AdminType.body.copyWith(
                                  color: AdminPalette.muted))
                        else ...[
                          Center(
                            child: DonutChart(
                              centerValue: '${data.activeSubscriptions}',
                              centerCaption: 'Active',
                              slices: [
                                for (var i = 0;
                                    i < data.planDistribution.length;
                                    i++)
                                  DonutSlice(
                                    value: data.planDistribution[i].percent,
                                    color: _palette[i % _palette.length],
                                    label: data.planDistribution[i].planName,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stackLg),
                          for (var i = 0;
                              i < data.planDistribution.length;
                              i++) ...[
                            _ShareRow(
                              share: data.planDistribution[i],
                              color: _palette[i % _palette.length],
                            ),
                            if (i != data.planDistribution.length - 1)
                              const SizedBox(height: AppSpacing.stackSm),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // Revenue by month.
                  RevenueTrendCard(
                      title: 'Revenue by Month', months: data.revenueByMonth),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  final PlanShare share;
  final Color color;
  const _ShareRow({required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(child: Text(share.planName, style: AdminType.body)),
        Text('${share.count} · ${share.percent}%',
            style: AdminType.rowTitle.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
