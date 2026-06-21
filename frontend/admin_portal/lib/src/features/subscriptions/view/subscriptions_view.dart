import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../components/billing_cycle_toggle.dart';
import '../components/plan_card.dart';
import '../controller/subscriptions_controller.dart';

/// Subscription Management — review and edit institutional pricing tiers.
class SubscriptionsView extends GetView<SubscriptionsController> {
  const SubscriptionsView({super.key});

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
            if (controller.error.value != null) {
              return Center(
                  child: Text(controller.error.value!, style: AppTypography.bodyLg));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackXl),
              children: [
                Text('Subscription\nManagement', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Review and update institutional pricing tiers.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                BillingCycleToggle(
                  value: controller.cycle.value,
                  onChanged: controller.setCycle,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                for (final plan in controller.plans) ...[
                  PlanCard(
                    plan: plan,
                    price: controller.priceFor(plan),
                    period: '/mo',
                    onEdit: () {},
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
