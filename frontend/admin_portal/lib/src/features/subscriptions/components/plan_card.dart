import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../models/subscription_plan.dart';

/// Pricing tier card: tier badge, price, tagline, a feature checklist, and an
/// Edit button. The most-popular tier gets an accent border + ribbon and a
/// filled (solid) edit button; others use an outlined button.
class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String price;
  final String period;
  final VoidCallback onEdit;

  const PlanCard({
    super.key,
    required this.plan,
    required this.price,
    required this.period,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = plan.accent.color;
    final highlighted = plan.mostPopular;

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: highlighted ? accent : AppColors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.06), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TierBadge(label: plan.tier, color: accent),
          const SizedBox(height: AppSpacing.stackMd),
          _Price(price: price, period: period, custom: plan.custom),
          const SizedBox(height: AppSpacing.stackSm),
          Text(plan.tagline, style: AppTypography.bodyMd),
          const SizedBox(height: AppSpacing.stackLg),
          for (final f in plan.features) ...[
            _FeatureRow(feature: f, accent: accent),
            const SizedBox(height: AppSpacing.stackMd),
          ],
          const SizedBox(height: AppSpacing.stackSm),
          if (highlighted)
            PrimaryButton(
              label: 'Edit ${plan.tier} Plan',
              expanded: true,
              trailingIcon: null,
              onPressed: onEdit,
            )
          else
            GhostButton(
              label: 'Edit ${plan.tier} Plan',
              expanded: true,
              onPressed: onEdit,
            ),
        ],
      ),
    );

    if (!highlighted) return card;
    // Ribbon overlay for the most-popular tier.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 0,
          right: AppSpacing.stackLg,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.sm)),
            ),
            child: Text(
              'MOST POPULAR',
              style: AppTypography.labelCaps.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TierBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _Price extends StatelessWidget {
  final String price;
  final String period;
  final bool custom;
  const _Price({required this.price, required this.period, required this.custom});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(price, style: AppTypography.displayLg.copyWith(fontSize: 40)),
        if (!custom) ...[
          const SizedBox(width: 4),
          Text(period, style: AppTypography.bodyLg),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final Color accent;
  const _FeatureRow({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    final included = feature.included;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          included ? Icons.check_circle_rounded : Icons.cancel_outlined,
          size: 18,
          color: included ? accent : AppColors.outline,
        ),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(
          child: Text(
            feature.label,
            style: AppTypography.bodyLg.copyWith(
              color: included ? AppColors.onSurface : AppColors.outline,
              fontWeight: feature.emphasized ? FontWeight.w700 : FontWeight.w400,
              decoration: included ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }
}
