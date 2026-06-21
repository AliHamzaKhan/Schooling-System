import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_search_field.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/bar_chart.dart';
import '../../../ui/admin_widgets/donut_chart.dart';
import '../../../ui/admin_widgets/multi_line_chart.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../components/analytics_metric_card.dart';
import '../controller/analytics_controller.dart';
import '../models/analytics_data.dart';

/// System Analytics — high-level performance and growth metrics.
class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AppTypography.bodyLg));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
              children: [
                Text('Analytics\nOverview', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('High-level system performance and growth metrics.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackMd),
                AdminSearchField(hint: 'Search schools or metrics…', onChanged: (_) {}),
                const SizedBox(height: AppSpacing.stackSm),
                _DateRangePill(),
                const SizedBox(height: AppSpacing.stackMd),

                // KPI tiles.
                for (final m in data.metrics) ...[
                  AnalyticsMetricCard(metric: m),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                const SizedBox(height: AppSpacing.stackSm),

                // User growth.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'User Growth Over Time'),
                      const SizedBox(height: 2),
                      Text('Cumulative students vs educators (YTD)',
                          style: AppTypography.bodySm),
                      const SizedBox(height: AppSpacing.stackLg),
                      MultiLineChart(
                        xLabels: data.months,
                        series: [
                          LineSeries(
                              points: data.students,
                              color: AppColors.primary,
                              label: 'Students'),
                          LineSeries(
                              points: data.educators,
                              color: AppColors.aiAccent,
                              label: 'Educators'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        children: const [
                          _LegendDot(color: AppColors.primary, label: 'Students'),
                          SizedBox(width: AppSpacing.stackLg),
                          _LegendDot(color: AppColors.aiAccent, label: 'Educators'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Subscriptions donut.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Subscriptions'),
                      const SizedBox(height: AppSpacing.stackLg),
                      Center(
                        child: DonutChart(
                          centerValue: data.totalActive,
                          centerCaption: 'Total Active',
                          slices: [
                            for (final s in data.subscriptionShares)
                              DonutSlice(
                                  value: s.percent.toDouble(),
                                  color: s.color,
                                  label: s.label),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      for (final s in data.subscriptionShares) ...[
                        _ShareRow(share: s),
                        if (s != data.subscriptionShares.last)
                          const SizedBox(height: AppSpacing.stackSm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Revenue by month.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                          title: 'Revenue by\nMonth',
                          actionLabel: 'Export',
                          onAction: () {}),
                      const SizedBox(height: 2),
                      Text('Gross revenue across all regions',
                          style: AppTypography.bodySm),
                      const SizedBox(height: AppSpacing.stackLg),
                      AdminBarChart(
                          values: data.revenueByMonth, labels: data.months),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _DateRangePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.stackSm),
          Text('Last 30 Days', style: AppTypography.labelMd),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.onSurfaceVariant),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodyMd),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  final SubscriptionShare share;
  const _ShareRow({required this.share});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: share.color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(child: Text(share.label, style: AppTypography.bodyLg)),
        Text('${share.percent}%',
            style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
