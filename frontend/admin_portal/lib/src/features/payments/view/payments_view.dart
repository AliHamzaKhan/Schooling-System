import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../components/payment_stat_card.dart';
import '../components/revenue_overview_card.dart';
import '../controller/payments_controller.dart';

/// Payments & Billing — revenue KPIs, a revenue overview chart, and a shortcut
/// into Subscription Management.
class PaymentsView extends GetView<PaymentsController> {
  const PaymentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminTopBar(title: 'Payments', showAvatar: true),
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
                Text('Manage revenue streams and recent transactions.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(child: _RangePill(label: controller.range.value)),
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
                for (final s in data.stats) ...[
                  PaymentStatCard(stat: s),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                const SizedBox(height: AppSpacing.stackSm),
                RevenueOverviewCard(revenue: data.revenue),
                const SizedBox(height: AppSpacing.stackLg),
                GhostButton(
                  label: 'Manage Subscription Plans',
                  expanded: true,
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: () => Get.toNamed(AdminRoutes.subscriptions),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _RangePill extends StatelessWidget {
  final String label;
  const _RangePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
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
          Expanded(child: Text(label, style: AppTypography.labelMd)),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
