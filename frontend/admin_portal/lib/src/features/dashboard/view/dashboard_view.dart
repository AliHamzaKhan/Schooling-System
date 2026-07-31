import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../../../ui/admin_widgets/stat_card.dart';
import '../components/alert_tile.dart';
import '../components/quick_action_card.dart';
import '../controller/dashboard_controller.dart';

/// Admin home — KPI cards, recent alerts feed, and primary quick actions.
class DashboardView extends GetView<DashboardController> {
  /// Invoked by the shell so the CTA can route / switch tabs.
  final VoidCallback? onCreateSchool;
  final VoidCallback? onManageHeadmasters;

  /// KPI card taps: Total Schools / Active Subscriptions / Monthly Revenue.
  final VoidCallback? onViewSchools;
  final VoidCallback? onViewSubscriptions;
  final VoidCallback? onViewRevenue;

  const DashboardView({
    super.key,
    this.onCreateSchool,
    this.onManageHeadmasters,
    this.onViewSchools,
    this.onViewSubscriptions,
    this.onViewRevenue,
  });

  /// Accent rail color per KPI card, cycled by index.
  static const _accents = [AppColors.primary, Color(0xFFE8A317), AppColors.aiAccent];

  /// Maps a KPI card index to its drill-in action (0=schools, 1=subscriptions,
  /// 2=revenue), matching the order the metrics are built in the repository.
  VoidCallback? _cardAction(int index) => switch (index) {
        0 => onViewSchools,
        1 => onViewSubscriptions,
        2 => onViewRevenue,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error.value != null) {
              return _ErrorState(
                message: controller.error.value!,
                onRetry: controller.load,
              );
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackSm,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl,
                ),
                children: [
                  // ── KPI cards (tap to drill into the matching screen) ──
                  for (var i = 0; i < controller.metrics.length; i++) ...[
                    StatCard(
                      metric: controller.metrics[i],
                      accent: _accents[i % _accents.length],
                      showTrend: false,
                      onTap: _cardAction(i),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                  ],
                  const SizedBox(height: AppSpacing.stackSm),

                  // ── Recent alerts (only when the feed has entries) ──
                  if (controller.alerts.isNotEmpty) ...[
                    GlassSurface(
                      padding: const EdgeInsets.all(AppSpacing.stackLg),
                      child: Column(
                        children: [
                          SectionHeader(
                            title: 'Recent Alerts',
                            actionLabel: 'View All',
                            onAction: () {},
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          for (final alert in controller.alerts) ...[
                            AlertTile(alert: alert),
                            if (alert != controller.alerts.last)
                              const SizedBox(height: AppSpacing.stackSm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],

                  // ── Quick actions ──────────────────────────────
                  QuickActionCard(
                    label: 'Create School',
                    leadingIcon: Icons.add,
                    watermarkIcon: Icons.add_business_rounded,
                    background: AppColors.primary,
                    filled: true,
                    onTap: onCreateSchool ?? () {},
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  QuickActionCard(
                    label: 'Manage Headmasters',
                    leadingIcon: Icons.settings,
                    watermarkIcon: Icons.manage_accounts_rounded,
                    background: AppColors.aiAccent.withValues(alpha: 0.18),
                    onTap: onManageHeadmasters ?? () {},
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.outline),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyLg),
            const SizedBox(height: AppSpacing.stackLg),
            GhostButton(label: 'Retry', onPressed: onRetry, trailingIcon: Icons.refresh),
          ],
        ),
      ),
    );
  }
}
