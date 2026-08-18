import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/outstanding_card.dart';
import '../components/overdue_row.dart';
import '../components/total_collected_card.dart';
import '../controller/fees_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Fee Management — collection KPIs, outstanding balances, and overdue list.
class FeesView extends GetView<FeesController> {
  const FeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(showAvatar: true),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 4)]));
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
                Text('Fee Management', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(
                  label: 'Record Payment',
                  leadingIcon: Icons.add,
                  trailingIcon: null,
                  onPressed: controller.recordPaymentFlow,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                GhostButton(
                  label: 'All Students · Fees',
                  leadingIcon: Icons.groups_rounded,
                  trailingIcon: Icons.chevron_right_rounded,
                  expanded: true,
                  onPressed: () =>
                      Get.toNamed(HeadmasterRoutes.feesRoster),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                TotalCollectedCard(data: data),
                const SizedBox(height: AppSpacing.stackLg),
                OutstandingCard(data: data, onRemindAll: controller.remindAll),
                const SizedBox(height: AppSpacing.stackLg),
                SectionHeader(
                  title: 'Overdue Payments',
                  actionLabel: 'View All',
                  onAction: () =>
                      Get.toNamed(HeadmasterRoutes.overduePayments),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                for (var i = 0; i < data.overdue.length; i++) ...[
                  OverdueRow(
                    payment: data.overdue[i],
                    onSend: () => controller.remind(data.overdue[i]),
                  ),
                  if (i != data.overdue.length - 1)
                    const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
