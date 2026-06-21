import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/outstanding_card.dart';
import '../components/overdue_row.dart';
import '../components/total_collected_card.dart';
import '../controller/fees_controller.dart';

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
                Text('Fee Management', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Overview of current academic year collections',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                PrimaryButton(
                  label: 'Record Payment',
                  leadingIcon: Icons.add,
                  trailingIcon: null,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.stackLg),
                TotalCollectedCard(data: data),
                const SizedBox(height: AppSpacing.stackLg),
                OutstandingCard(data: data, onRemindAll: () {}),
                const SizedBox(height: AppSpacing.stackLg),
                SectionHeader(
                  title: 'Overdue Payments',
                  actionLabel: 'View All',
                  onAction: () {},
                ),
                const SizedBox(height: AppSpacing.stackMd),
                for (var i = 0; i < data.overdue.length; i++) ...[
                  OverdueRow(payment: data.overdue[i], onSend: () {}),
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
