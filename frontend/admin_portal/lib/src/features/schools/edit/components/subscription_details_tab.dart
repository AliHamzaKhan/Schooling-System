import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/status_pill.dart';
import 'edit_section_card.dart';

/// Subscription Details tab — current plan summary, billing, and limits.
class SubscriptionDetailsTab extends StatelessWidget {
  const SubscriptionDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EditSectionCard(
          title: 'Current Plan',
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pro', style: AppTypography.displayLg.copyWith(fontSize: 32)),
                      Text('\$799 / month', style: AppTypography.bodyLg),
                    ],
                  ),
                ),
                const StatusPill(label: 'Active', color: AppColors.tertiary, icon: Icons.circle),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            GhostButton(label: 'Change Plan', expanded: true, onPressed: () {}),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
        EditSectionCard(
          title: 'Billing',
          accent: const Color(0xFFE8A317),
          children: const [
            _Row(label: 'Billing Cycle', value: 'Monthly'),
            Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
            _Row(label: 'Next Renewal', value: 'Jul 1, 2026'),
            Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
            _Row(label: 'Payment Method', value: 'Visa •••• 4242'),
          ],
        ),
        const SizedBox(height: AppSpacing.stackLg),
        EditSectionCard(
          title: 'Plan Limits',
          accent: AppColors.aiAccent,
          children: const [
            _Row(label: 'Student Seats', value: '1,245 / 2,500'),
            Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
            _Row(label: 'Staff Accounts', value: '84 / 250'),
            Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
            _Row(label: 'API Access', value: 'Enabled'),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyLg),
        Text(value, style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
