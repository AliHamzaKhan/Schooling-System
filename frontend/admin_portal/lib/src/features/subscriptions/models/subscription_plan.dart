import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Visual accent theme for a plan tier card.
enum PlanAccent { basic, pro, enterprise }

extension PlanAccentX on PlanAccent {
  Color get color => switch (this) {
        PlanAccent.basic => AppColors.primary,
        PlanAccent.pro => const Color(0xFFE8A317),
        PlanAccent.enterprise => AppColors.aiAccent,
      };
}

/// A single feature line within a plan, optionally excluded (struck through).
class PlanFeature {
  final String label;
  final bool included;

  /// Bold lead-in like "Everything in Basic".
  final bool emphasized;

  const PlanFeature(this.label, {this.included = true, this.emphasized = false});
}

/// A subscription pricing tier shown on the Subscription Management screen.
class SubscriptionPlan {
  final String tier;
  final String monthlyPrice;
  final String yearlyPrice;

  /// True for tiers quoted as "Custom" (no per-period number).
  final bool custom;
  final String tagline;
  final List<PlanFeature> features;
  final bool mostPopular;
  final PlanAccent accent;

  const SubscriptionPlan({
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.tagline,
    required this.features,
    required this.accent,
    this.custom = false,
    this.mostPopular = false,
  });
}
