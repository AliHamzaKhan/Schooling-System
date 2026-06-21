import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/create_school_controller.dart';

/// Wizard step 3 — pick the starting subscription plan.
class StepInitialPlan extends StatelessWidget {
  final CreateSchoolController controller;
  const StepInitialPlan({super.key, required this.controller});

  static const _blurbs = {
    'Basic': 'Up to 500 students · core tools',
    'Pro': 'Up to 2,500 students · advanced analytics',
    'Enterprise': 'Unlimited students · custom integrations',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial Plan', style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Choose the subscription tier this school starts on.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackLg),
        Obx(() => Column(
              children: [
                for (final plan in CreateSchoolController.plans) ...[
                  _PlanOption(
                    title: plan,
                    subtitle: _blurbs[plan] ?? '',
                    selected: controller.selectedPlan.value == plan,
                    onTap: () => controller.selectPlan(plan),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            )),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.subtitle,
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
                  Text(title,
                      style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodyMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
