import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/multi_line_chart.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/ring_chart.dart';
import '../../../../../widgets/section_header.dart';
import '../components/attendance_metric_tile.dart';
import '../components/grade_breakdown_row.dart';
import '../controller/attendance_controller.dart';
import '../models/attendance_data.dart';

/// Attendance Overview — daily KPIs, rate rings, trend chart, grade breakdown.
class AttendanceView extends GetView<AttendanceController> {
  final VoidCallback? onAnalytics;
  const AttendanceView({super.key, this.onAnalytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
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
                const _DatePill(label: 'Today, Oct 24'),
                const SizedBox(height: AppSpacing.stackMd),
                Text('Attendance\nOverview', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Daily check-ins for the entire island.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(child: GhostButton(label: 'Filter', leadingIcon: Icons.filter_list_rounded, expanded: true, onPressed: () {})),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Export',
                        leadingIcon: Icons.download_rounded,
                        trailingIcon: null,
                        expanded: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                for (final m in data.metrics) ...[
                  AttendanceMetricTile(metric: m),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                const SizedBox(height: AppSpacing.stackSm),

                // Daily rates rings.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Daily Rates'),
                      const SizedBox(height: AppSpacing.stackLg),
                      Center(
                        child: Column(
                          children: [
                            RingChart(
                              progress: data.studentRatePercent / 100,
                              color: AppColors.primary,
                              value: '${data.studentRatePercent}%',
                              caption: 'Students',
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                            RingChart(
                              progress: data.teacherRatePercent / 100,
                              color: const Color(0xFFE8A317),
                              value: '${data.teacherRatePercent}%',
                              caption: 'Teachers',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Trend chart.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Attendance\nTrend', style: AppTypography.titleLg),
                          ),
                          Obx(() => _RangeToggle(
                                value: controller.range.value,
                                onChanged: controller.selectRange,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      PortalMultiLineChart(
                        xLabels: data.trendLabels,
                        series: [
                          LineSeries(
                              points: data.studentTrend,
                              color: AppColors.primary,
                              label: 'Students'),
                          LineSeries(
                              points: data.teacherTrend,
                              color: const Color(0xFFE8A317),
                              label: 'Teachers'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _LegendDot(color: AppColors.primary, label: 'Students'),
                          SizedBox(width: AppSpacing.stackLg),
                          _LegendDot(color: Color(0xFFE8A317), label: 'Teachers'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Grade breakdown.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Grade Level Breakdown'),
                      const SizedBox(height: AppSpacing.stackLg),
                      for (final g in data.grades) ...[
                        GradeBreakdownRow(grade: g),
                        if (g != data.grades.last)
                          const SizedBox(height: AppSpacing.stackMd),
                      ],
                      const SizedBox(height: AppSpacing.stackLg),
                      GhostButton(label: 'View All Grades', expanded: true, onPressed: () {}),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(
                  label: 'Open Reports & Analytics',
                  trailingIcon: Icons.arrow_forward,
                  expanded: true,
                  onPressed: onAnalytics,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final AttendanceRange value;
  final ValueChanged<AttendanceRange> onChanged;
  const _RangeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('Wk', value == AttendanceRange.week,
              () => onChanged(AttendanceRange.week)),
          _segment('Mo', value == AttendanceRange.month,
              () => onChanged(AttendanceRange.month)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
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
