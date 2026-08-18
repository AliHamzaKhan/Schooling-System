import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../controller/subscriptions_controller.dart';
import '../models/plan_features.dart';
import '../models/subscription_models.dart';
import '../../../ui/admin_theme.dart';

/// Subscription Plans — the admin-editable products. Each plan carries a price
/// and a billing duration (Monthly / 6-Month / Annual); admins can add, edit,
/// or archive plans at any time.
class SubscriptionsView extends GetView<SubscriptionsController> {
  const SubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                    child: Text(controller.error.value!,
                        style: AdminType.body));
              }
              return RefreshIndicator(
                onRefresh: controller.fetch,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerPaddingMobile,
                      0,
                      AppSpacing.containerPaddingMobile,
                      AppSpacing.stackXl),
                  children: [
                    Text('Subscription\nPlans', style: AdminType.screenTitle),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text('Add, edit, or archive pricing plans at any time.',
                        style: AdminType.body),
                    const SizedBox(height: AppSpacing.stackLg),
                    PrimaryButton(
                      label: 'New Plan',
                      leadingIcon: Icons.add,
                      trailingIcon: null,
                      onPressed: () => _openPlanForm(context),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (controller.plans.isEmpty)
                      Text('No plans yet. Create your first plan.',
                          style: AdminType.body
                              .copyWith(color: AdminPalette.muted))
                    else
                      for (final plan in controller.plans) ...[
                        _PlanCard(
                          plan: plan,
                          onEdit: () => _openPlanForm(context, plan: plan),
                          onArchive: () => _confirmArchive(plan),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                      ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openPlanForm(BuildContext context, {SubscriptionPlanModel? plan}) {
    Get.toNamed<void>(AdminRoutes.planForm, arguments: plan);
  }

  Future<void> _confirmArchive(SubscriptionPlanModel plan) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Archive plan?'),
        content: Text(
            '${plan.name} will be hidden from new subscriptions. Existing subscriptions keep their pricing.'),
        actions: [
          TextButton(
              onPressed: () => Get.back<bool>(result: false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Archive',
                style: TextStyle(color: AdminPalette.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await controller.archivePlan(plan);
  }
}

String _money(double v) =>
    '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

/// Accent color per billing duration, so the three durations read distinctly.
Color _accentFor(BillingPeriod p) => switch (p) {
      BillingPeriod.monthly => AdminPalette.ink,
      BillingPeriod.sixMonth => AdminPalette.info,
      BillingPeriod.annual => AdminPalette.warning,
    };

/// The catalog features a plan has switched on, in catalog order.
List<PlanFeature> _enabledFeatures(SubscriptionPlanModel plan) {
  final on = plan.modules.toSet();
  return [
    for (final g in kPlanFeatureGroups)
      for (final f in g.features)
        if (on.contains(f.key)) f,
  ];
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(plan.billingPeriod);
    final features = _enabledFeatures(plan);
    return Container(
      decoration: BoxDecoration(
        color: AdminPalette.card,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: AdminPalette.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.07), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: plan.billingPeriod.label, color: accent),
              const SizedBox(width: AppSpacing.stackSm),
              _Chip(
                label: plan.maxStudents == null
                    ? 'Unlimited students'
                    : 'Up to ${plan.maxStudents} students',
                color: accent,
                subtle: true,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.archive_outlined,
                    color: AdminPalette.muted),
                tooltip: 'Archive',
                visualDensity: VisualDensity.compact,
                onPressed: onArchive,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(plan.name, style: AdminType.cardTitle),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_money(plan.price),
                  style: AdminType.metric
                      .copyWith(fontSize: 40, color: accent)),
              const SizedBox(width: 4),
              Text(plan.billingPeriod.priceSuffix, style: AdminType.body),
            ],
          ),
          if (plan.description != null && plan.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(plan.description!, style: AdminType.body),
          ],

          // ── What's included: the enabled add-on features ──
          const SizedBox(height: AppSpacing.stackMd),
          Divider(color: AdminPalette.divider, height: 1),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Text(
                features.isEmpty ? 'No add-ons' : "What's included",
                style: AdminType.label.copyWith(
                    color: AdminPalette.muted, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (features.isNotEmpty)
                Text('${features.length} feature${features.length == 1 ? '' : 's'}',
                    style: AdminType.meta.copyWith(color: AdminPalette.faint)),
            ],
          ),
          if (features.isEmpty) ...[
            const SizedBox(height: 6),
            Text('Toggle features on with Edit Plan.',
                style: AdminType.meta.copyWith(color: AdminPalette.faint)),
          ] else ...[
            const SizedBox(height: AppSpacing.stackSm),
            for (final f in features)
              _FeatureLine(feature: f, accent: accent),
          ],

          const SizedBox(height: AppSpacing.stackLg),
          PrimaryButton(
            label: 'Edit Plan',
            expanded: true,
            trailingIcon: null,
            leadingIcon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// One "included feature" row on a plan card: a check badge, the feature's
/// icon, and its label — matching the toggles on the plan editor.
class _FeatureLine extends StatelessWidget {
  final PlanFeature feature;
  final Color accent;
  const _FeatureLine({required this.feature, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 13, color: accent),
          ),
          const SizedBox(width: 10),
          Icon(feature.icon, size: 16, color: AdminPalette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(feature.label,
                style: AdminType.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;
  const _Chip({required this.label, required this.color, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AdminType.label
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
