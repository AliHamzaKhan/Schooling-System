import 'package:shared/shared.dart';

import 'subscription_plan.dart';

/// Loads the configurable subscription pricing tiers.
class SubscriptionsRepository {
  Future<ApiResponse<List<SubscriptionPlan>>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_plans);
  }

  static const _plans = <SubscriptionPlan>[
    SubscriptionPlan(
      tier: 'Basic',
      monthlyPrice: '\$299',
      yearlyPrice: '\$239',
      tagline: 'Essential tools for small schools starting their digital journey.',
      accent: PlanAccent.basic,
      features: [
        PlanFeature('Up to 500 Students'),
        PlanFeature('Core Curriculum Delivery'),
        PlanFeature('Basic Reporting'),
        PlanFeature('Advanced Analytics', included: false),
      ],
    ),
    SubscriptionPlan(
      tier: 'Pro',
      monthlyPrice: '\$799',
      yearlyPrice: '\$639',
      tagline: 'Comprehensive suite for growing institutions.',
      accent: PlanAccent.pro,
      mostPopular: true,
      features: [
        PlanFeature('Everything in Basic', emphasized: true),
        PlanFeature('Up to 2,500 Students'),
        PlanFeature('Advanced Performance Analytics'),
        PlanFeature('Parent Portal Access'),
      ],
    ),
    SubscriptionPlan(
      tier: 'Enterprise',
      monthlyPrice: 'Custom',
      yearlyPrice: 'Custom',
      custom: true,
      tagline: 'Tailored architecture for districts and large networks.',
      accent: PlanAccent.enterprise,
      features: [
        PlanFeature('Everything in Pro', emphasized: true),
        PlanFeature('Unlimited Students'),
        PlanFeature('Custom Integrations (API)'),
        PlanFeature('Dedicated Success Manager'),
      ],
    ),
  ];
}
