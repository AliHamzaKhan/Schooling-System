import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../controller/subscriptions_controller.dart';

/// Segmented Monthly / Yearly toggle. Yearly shows a "-20%" savings hint.
class BillingCycleToggle extends StatelessWidget {
  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  const BillingCycleToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Monthly',
            selected: value == BillingCycle.monthly,
            onTap: () => onChanged(BillingCycle.monthly),
          ),
          _Segment(
            label: 'Yearly',
            trailing: '-20%',
            selected: value == BillingCycle.yearly,
            onTap: () => onChanged(BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(
                trailing!,
                style: AppTypography.labelCaps.copyWith(
                  color: selected ? AppColors.tertiaryFixed : AppColors.tertiary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
