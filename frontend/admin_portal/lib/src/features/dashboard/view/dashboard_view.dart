import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/admin_theme.dart';
import '../../../ui/admin_widgets/admin_surface.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../../../ui/admin_widgets/stat_card.dart';
import '../components/alert_tile.dart';
import '../components/quick_action_card.dart';
import '../controller/dashboard_controller.dart';

/// Admin home — a welcome header, KPI cards, the recent alerts feed, and the
/// primary quick actions.
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

  /// Icon per KPI card, in the order the repository builds the metrics
  /// (0=schools, 1=subscriptions, 2=revenue).
  static const _icons = [
    Icons.apartment_rounded,
    Icons.verified_rounded,
    Icons.bar_chart_rounded,
  ];

  /// Maps a KPI card index to its drill-in action.
  VoidCallback? _cardAction(int index) => switch (index) {
        0 => onViewSchools,
        1 => onViewSubscriptions,
        2 => onViewRevenue,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return AdminScreen(
      child: Column(
        children: [
          const AdminTopBar(showAvatar: true),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AdminPalette.ink),
                );
              }
              if (controller.error.value != null) {
                return _ErrorState(
                  message: controller.error.value!,
                  onRetry: controller.load,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                color: AdminPalette.ink,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      kAdminGutter, 4, kAdminGutter, 36),
                  children: [
                    const AdminPageHeader(
                      title: 'Welcome Back, Admin',
                      subtitle:
                          "Here is an overview of your platform's performance today.",
                    ),

                    // ── KPI cards (tap to drill into the matching screen) ──
                    for (var i = 0; i < controller.metrics.length; i++) ...[
                      StatCard(
                        metric: controller.metrics[i],
                        icon: _icons[i % _icons.length],
                        emphasized: i == 0,
                        showTrend: false,
                        onTap: _cardAction(i),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Recent alerts (only when the feed has entries) ──
                    if (controller.alerts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AdminCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            SectionHeader(
                              title: 'Recent Alerts',
                              actionLabel: 'View All',
                              onAction: () {},
                            ),
                            const SizedBox(height: 16),
                            for (final alert in controller.alerts) ...[
                              AlertTile(alert: alert),
                              if (alert != controller.alerts.last)
                                const Divider(
                                    height: 28, color: AdminPalette.divider),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // ── Quick actions ──────────────────────────────
                    const SizedBox(height: 28),
                    Text('Quick Actions', style: AdminType.sectionTitle),
                    const SizedBox(height: 14),
                    QuickActionCard(
                      label: 'Create New School',
                      description:
                          'Add a new institution to the platform and invite administrators.',
                      leadingIcon: Icons.add_rounded,
                      watermarkIcon: Icons.add_business_rounded,
                      onTap: onCreateSchool ?? () {},
                    ),
                    const SizedBox(height: 14),
                    AdminNavTile(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Manage Headmasters',
                      subtitle: 'Review and manage user roles.',
                      onTap: onManageHeadmasters ?? () {},
                    ),
                    const SizedBox(height: 14),
                    AdminNavTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Manage Subscriptions',
                      subtitle: 'View plans and billing details.',
                      onTap: onViewSubscriptions ?? () {},
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdminIconTile(icon: Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AdminType.body),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AdminPalette.ink,
                textStyle: AdminType.label,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: AdminPalette.tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
