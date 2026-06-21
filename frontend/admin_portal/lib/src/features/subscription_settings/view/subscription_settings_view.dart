import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../app/admin_routes.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../../../ui/admin_widgets/segmented_pills.dart';
import '../../../ui/admin_widgets/setting_switch_tile.dart';
import '../../../ui/admin_widgets/status_pill.dart';
import '../controller/subscription_settings_controller.dart';
import '../models/subscription_settings_models.dart';

/// Subscription Settings — current plan hero, billing-cycle segmented control,
/// auto-renew toggle, per-resource usage meters, and a link to change plans.
class SubscriptionSettingsView
    extends GetView<SubscriptionSettingsController> {
  const SubscriptionSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTopBar(
            title: 'Subscription',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final s = controller.settings.value;
              if (s == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  _PlanHero(settings: s),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Billing'),
                  const SizedBox(height: AppSpacing.stackMd),
                  GlassSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Billing Cycle',
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.stackSm),
                        SegmentedPills(
                          options: const ['Monthly', 'Annual'],
                          selected: s.billingCycle,
                          accent: AppColors.primary,
                          onSelected: controller.setCycle,
                        ),
                        const Divider(
                            height: AppSpacing.stackXl,
                            color: AppColors.outlineVariant),
                        SettingSwitchTile(
                          icon: Icons.autorenew_rounded,
                          title: 'Auto-Renew',
                          subtitle: 'Renew automatically on ${s.renewalDate}',
                          value: s.autoRenew,
                          onChanged: controller.setAutoRenew,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Usage & Limits'),
                  const SizedBox(height: AppSpacing.stackMd),
                  GlassSurface(
                    child: Column(
                      children: [
                        for (var i = 0; i < s.usage.length; i++) ...[
                          _UsageBar(metric: s.usage[i]),
                          if (i != s.usage.length - 1)
                            const SizedBox(height: AppSpacing.stackLg),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  PrimaryButton(
                    label: 'Change Plan',
                    expanded: true,
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () => Get.toNamed(AdminRoutes.subscriptions),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PlanHero extends StatelessWidget {
  final SubscriptionSettings settings;
  const _PlanHero({required this.settings});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Current Plan', style: AppTypography.bodyLg),
              ),
              const StatusPill(label: 'Active', color: AppColors.tertiary),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(settings.planName,
                  style: AppTypography.displayLg.copyWith(fontSize: 32)),
              const SizedBox(width: AppSpacing.stackSm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(settings.priceLabel,
                    style: AppTypography.titleMd
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              const Icon(Icons.event_repeat_outlined,
                  size: 15, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                  '${settings.billingCycle} · renews ${settings.renewalDate}',
                  style: AppTypography.bodyMd),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final UsageMetric metric;
  const _UsageBar({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = metric.nearLimit ? AppColors.error : AppColors.primary;
    final unit = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(metric.label,
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Text('${metric.used}$unit / ${metric.limit}$unit',
                style: AppTypography.labelMd.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: metric.ratio,
            minHeight: 8,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
