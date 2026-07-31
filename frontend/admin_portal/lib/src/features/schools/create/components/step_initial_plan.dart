import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../subscriptions/models/subscription_models.dart';
import '../controller/create_school_controller.dart';

/// Wizard step 3 — assign the subscription: pick a live plan and, optionally,
/// apply a discount (percentage or fixed amount). A subscription is required to
/// finish setup.
class StepInitialPlan extends StatelessWidget {
  final CreateSchoolController controller;
  const StepInitialPlan({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription',
            style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Assign a plan for this school. A subscription is required.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackLg),
        Obx(() {
          if (controller.loadingPlans.value) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.stackLg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.plans.isEmpty) {
            return Text(
              'No subscription plans exist yet. Create a plan first '
              '(Settings → Subscription Plans).',
              style: AppTypography.bodyLg.copyWith(color: AppColors.error),
            );
          }
          return Column(
            children: [
              for (final plan in controller.plans) ...[
                _PlanOption(
                  plan: plan,
                  selected: controller.selectedPlanId.value == plan.id,
                  onTap: () => controller.selectPlan(plan.id),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
              const SizedBox(height: AppSpacing.stackSm),
              _DiscountSection(controller: controller),
              const SizedBox(height: AppSpacing.stackMd),
              _PriceSummary(controller: controller),
            ],
          );
        }),
      ],
    );
  }
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

class _PlanOption extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.outline,
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${_money(plan.price)} ${plan.billingPeriod.priceSuffix}',
                      style: AppTypography.bodyMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountSection extends StatelessWidget {
  final CreateSchoolController controller;
  const _DiscountSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discount', style: AppTypography.titleMd),
        const SizedBox(height: AppSpacing.stackSm),
        Obx(() => Row(
              children: [
                for (final t in DiscountType.values) ...[
                  _DiscountChip(
                    label: switch (t) {
                      DiscountType.none => 'None',
                      DiscountType.percent => 'Percent %',
                      DiscountType.fixed => 'Fixed \$',
                    },
                    selected: controller.discountType.value == t,
                    onTap: () => controller.setDiscountType(t),
                  ),
                  if (t != DiscountType.values.last)
                    const SizedBox(width: AppSpacing.stackSm),
                ],
              ],
            )),
        Obx(() {
          if (controller.discountType.value == DiscountType.none) {
            return const SizedBox.shrink();
          }
          final isPercent = controller.discountType.value == DiscountType.percent;
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.stackSm),
            child: TextField(
              controller: controller.discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => controller.discountType.refresh(),
              decoration: InputDecoration(
                labelText: isPercent ? 'Percent off' : 'Amount off',
                prefixText: isPercent ? null : '\$ ',
                suffixText: isPercent ? '%' : null,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DiscountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DiscountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Text(label,
            style: AppTypography.labelMd.copyWith(
                color:
                    selected ? AppColors.onPrimary : AppColors.onSurfaceVariant)),
      ),
    );
  }
}

/// Live net-price preview after the discount is applied.
class _PriceSummary extends StatelessWidget {
  final CreateSchoolController controller;
  const _PriceSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final plan = controller.selectedPlan;
      if (plan == null) return const SizedBox.shrink();
      final base = plan.price;
      final type = controller.discountType.value;
      final raw = double.tryParse(controller.discountCtrl.text.trim()) ?? 0;
      double net = base;
      if (type == DiscountType.percent) {
        net = base * (1 - raw / 100);
      } else if (type == DiscountType.fixed) {
        net = base - raw;
      }
      if (net < 0) net = 0;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Due for first ${plan.billingPeriod.label} term',
                  style: AppTypography.bodyMd),
            ),
            if (net != base) ...[
              Text(_money(base),
                  style: AppTypography.bodyMd.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.onSurfaceVariant)),
              const SizedBox(width: 8),
            ],
            Text(_money(net), style: AppTypography.titleLg),
          ],
        ),
      );
    });
  }
}
