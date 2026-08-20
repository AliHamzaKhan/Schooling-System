import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../subscriptions/models/subscription_models.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';

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
            style: AdminType.screenTitle.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Assign a plan for this school. A subscription is required.',
            style: AdminType.body),
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
              style: AdminType.body.copyWith(color: AdminPalette.danger),
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
    v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
              ? AdminPalette.ink.withValues(alpha: 0.06)
              : AdminPalette.card,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? AdminPalette.ink : AdminPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? AppIcons.radioButtonChecked : AppIcons.radioButtonOff,
              color: selected ? AdminPalette.ink : AdminPalette.faint,
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name,
                      style: AdminType.rowTitle
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      '${_money(plan.price)} ${plan.billingPeriod.priceSuffix}'
                      '  ·  ${plan.maxStudents == null ? 'Unlimited' : plan.maxStudents} students',
                      style: AdminType.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountSection extends StatefulWidget {
  final CreateSchoolController controller;
  const _DiscountSection({required this.controller});

  @override
  State<_DiscountSection> createState() => _DiscountSectionState();
}

class _DiscountSectionState extends State<_DiscountSection>
    with ScreenTextControllers {
  CreateSchoolController get controller => widget.controller;

  // The discount field belongs to this section — disposed when the wizard
  // leaves the subscription step; the value stays on the controller.
  late final _discountCtrl = boundController(controller.discount);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discount', style: AdminType.rowTitle),
        const SizedBox(height: AppSpacing.stackSm),
        Obx(() => Row(
              children: [
                for (final t in DiscountType.values) ...[
                  _DiscountChip(
                    label: switch (t) {
                      DiscountType.none => 'None',
                      DiscountType.percent => 'Percent %',
                      DiscountType.fixed => 'Fixed amount',
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
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => controller.discountType.refresh(),
              decoration: InputDecoration(
                labelText: isPercent ? 'Percent off' : 'Amount off',
                prefixText: null,
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
              ? AdminPalette.ink
              : AdminPalette.card,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AdminPalette.ink : AdminPalette.border,
          ),
        ),
        child: Text(label,
            style: AdminType.label.copyWith(
                color:
                    selected ? Colors.white : AdminPalette.muted)),
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
      final raw = double.tryParse(controller.discount.value.trim()) ?? 0;
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
          color: AdminPalette.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Due for first ${plan.billingPeriod.label} term',
                  style: AdminType.body),
            ),
            if (net != base) ...[
              Text(_money(base),
                  style: AdminType.body.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AdminPalette.muted)),
              const SizedBox(width: 8),
            ],
            Text(_money(net), style: AdminType.cardTitle),
          ],
        ),
      );
    });
  }
}
