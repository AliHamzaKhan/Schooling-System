import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/models/admin_metrics.dart';
import '../controller/revenue_controller.dart';

/// Revenue report — subscription earnings grouped by calendar month. Opened
/// from the dashboard's "Monthly Revenue" KPI card.
class RevenueView extends GetView<RevenueController> {
  const RevenueView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeArea: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.value != null) {
                  return Center(
                      child: Text(controller.error.value!,
                          style: AppTypography.bodyLg));
                }
                final report = controller.report.value;
                if (report == null || report.months.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackMd,
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackXl,
                    ),
                    children: [
                      _TotalCard(total: report.total),
                      const SizedBox(height: AppSpacing.stackLg),
                      Text('Monthly earnings', style: AppTypography.titleMd),
                      const SizedBox(height: AppSpacing.stackMd),
                      for (final m in report.months.reversed) ...[
                        _MonthRow(
                          month: m,
                          maxTotal: report.months
                              .map((e) => e.total)
                              .fold<double>(0, (a, b) => a > b ? a : b),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

/// "2026-07" → "Jul 2026".
String _monthLabel(String ym) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  final mi = int.tryParse(parts[1]) ?? 0;
  if (mi < 1 || mi > 12) return ym;
  return '${names[mi - 1]} ${parts[0]}';
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.l1,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total (last 12 months)', style: AppTypography.bodyMd),
          const SizedBox(height: 4),
          Text(_money(total),
              style: AppTypography.displayLg.copyWith(fontSize: 34)),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final RevenueMonth month;
  final double maxTotal;
  const _MonthRow({required this.month, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final fraction = maxTotal <= 0 ? 0.0 : (month.total / maxTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(_monthLabel(month.month),
                  style: AppTypography.bodyLg),
            ),
            Text(_money(month.total), style: AppTypography.titleMd),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
        Text('${month.count} payment${month.count == 1 ? '' : 's'}',
            style: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackSm,
        AppSpacing.containerPaddingMobile,
        AppSpacing.stackLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAD6), Color(0xFFF3DCE6), Color(0xFFD9CDEF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back<void>(),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.onPrimary, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Text('EduMaster Admin',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Revenue',
              style: AppTypography.displayLg
                  .copyWith(color: AppColors.primary, fontSize: 34)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Subscription earnings by month.',
              style:
                  AppTypography.bodyLg.copyWith(color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.outline),
        SizedBox(height: AppSpacing.stackMd),
        Center(child: Text('No revenue recorded yet.')),
      ],
    );
  }
}
