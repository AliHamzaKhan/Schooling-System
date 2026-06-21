import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/multi_line_chart.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/enrollment_distribution_chart.dart';
import '../components/report_metric_card.dart';
import '../controller/reports_controller.dart';
import '../models/reports_data.dart';

/// Reports & Analytics — high-level insights with sparkline KPIs, a YoY
/// performance line chart, and an enrollment distribution bar chart.
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          PortalTopBar(onBell: () => Get.back<void>()),
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
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Reports &\nAnalytics',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'High-level insights across enrollment, academic performance, '
                    'and financial health for the current academic year.',
                    style: AppTypography.bodyLg,
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final m in data.metrics) ...[
                    ReportMetricCard(metric: m),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                  const SizedBox(height: AppSpacing.stackSm),
                  _PerformanceCard(data: data, controller: controller),
                  const SizedBox(height: AppSpacing.stackLg),
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enrollment Distribution', style: AppTypography.titleLg),
                        const SizedBox(height: 2),
                        Text('By Year Group', style: AppTypography.bodySm),
                        const SizedBox(height: AppSpacing.stackLg),
                        EnrollmentDistributionChart(data: data.enrollmentByYear),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final ReportsData data;
  final ReportsController controller;
  const _PerformanceCard({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Academic Performance Trends', style: AppTypography.titleLg),
          const SizedBox(height: 2),
          Text('Year-over-year comparison of average scores',
              style: AppTypography.bodySm),
          const SizedBox(height: AppSpacing.stackMd),
          _RangeToggle(
            value: controller.range.value,
            onChanged: controller.selectRange,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          PortalMultiLineChart(
            xLabels: data.performanceLabels,
            series: [
              LineSeries(
                points: data.previousYearScores,
                color: AppColors.outline,
                label: 'Previous Year',
                fill: false,
              ),
              LineSeries(
                points: data.currentYearScores,
                color: AppColors.primary,
                label: 'Current Year',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: AppColors.primary, label: 'Current Year'),
              SizedBox(width: AppSpacing.stackLg),
              _LegendDot(color: AppColors.outline, label: 'Previous Year'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final PerformanceRange value;
  final ValueChanged<PerformanceRange> onChanged;
  const _RangeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _segment('Term', value == PerformanceRange.term,
            () => onChanged(PerformanceRange.term)),
        const SizedBox(width: AppSpacing.stackSm),
        _segment('Year', value == PerformanceRange.year,
            () => onChanged(PerformanceRange.year)),
      ],
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(label,
            style: AppTypography.labelMd.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant)),
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
