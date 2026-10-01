import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/dashboard_kit.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/campus_hero_banner.dart';
import '../../../../../widgets/section_header.dart';
import '../../attendance/components/teacher_attendance_card.dart';
import '../components/dashboard_metric_card.dart';
import '../components/module_directory.dart';
import '../components/pending_approval_row.dart';
import '../components/recent_announcement_row.dart';
import '../controller/dashboard_controller.dart';
import '../models/dashboard_data.dart';
import '../models/subscription_status.dart';
import '../../../../../widgets/skeletons.dart';

/// Headmaster Dashboard — the shared dashboard shape (identity, the numbers,
/// the primary action, then shortcuts), then the campus-wide sections only this
/// module has: teacher attendance, pending approvals, recent announcements.
///
/// The KPI grid keeps [DashboardMetricCard] rather than the shared stat card:
/// it is the same 2-per-row shape and the same visual family, but it also
/// carries a trend pill and a "+ create" affordance, and swapping it for the
/// plain card would have quietly removed both.
class DashboardView extends GetView<HeadmasterDashboardController> {
  final VoidCallback? onAnnouncements;
  final VoidCallback? onSettings;
  final VoidCallback? onSalary;
  final Set<String>? enabledModules;

  const DashboardView({
    super.key,
    this.onAnnouncements,
    this.onSettings,
    this.onSalary,
    this.enabledModules,
  });

  bool _enabled(String module) =>
      enabledModules == null || enabledModules!.contains(module);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalTopBar(onBell: onAnnouncements),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(
                body: Column(
                  children: [
                    SkeletonStatGrid(count: 4),
                    SizedBox(height: AppSpacing.stackLg),
                    SkeletonCardList(count: 3),
                  ],
                ),
              );
            }
            final data = controller.data.value;
            if (data == null) {
              return AppStateView.error(
                title: 'Could not load this page',
                message:
                    controller.error.value ??
                    'The latest information is unavailable.',
                actionLabel: 'Retry',
                onAction: controller.load,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                0,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl,
              ),
              children: [
                const SizedBox(height: AppSpacing.stackSm),
                CampusHeroBanner(
                  name: controller.schoolName.value.isEmpty
                      ? 'Your Campus'
                      : controller.schoolName.value,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text(
                  'Hi! ${controller.headmasterName}',
                  style: AppTypography.headlineLg.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Subscription expiry alert (only near/after expiry).
                if (_ExpiryAlert.shouldShow(controller.subscription.value)) ...[
                  _ExpiryAlert(status: controller.subscription.value!),
                  const SizedBox(height: AppSpacing.stackLg),
                ],

                // Leave requests are the one item here that is somebody
                // waiting on a decision, so they get the full-width row and the
                // rest become shortcuts.
                if (_enabled('leave_management')) ...[
                  DashboardPrimaryAction(
                    icon: AppIcons.eventAvailableOutlined,
                    label: 'Leave Requests',
                    subtitle: 'Staff and student applications to review',
                    onTap: () => Get.toNamed(HeadmasterRoutes.leaveReview),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ],

                DashboardQuickLinks(
                  links: [
                    DashboardLink(
                      icon: AppIcons.settingsOutlined,
                      label: 'Settings',
                      onTap: onSettings,
                    ),
                    if (_enabled('hr_payroll'))
                      DashboardLink(
                        icon: AppIcons.paymentsOutlined,
                        label: 'Salaries',
                        onTap: onSalary,
                      ),
                    DashboardLink(
                      icon: AppIcons.apartmentRounded,
                      label: 'School Info',
                      onTap: () => Get.toNamed(HeadmasterRoutes.schoolInfoEdit),
                    ),
                    if (_enabled('transport'))
                      DashboardLink(
                        icon: AppIcons.directionsBusOutlined,
                        label: 'Transport',
                        onTap: () => Get.toNamed(HeadmasterRoutes.transport),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // One discoverable directory for every management module.
                // This is especially important on web, where headmasters expect
                // a control panel rather than hidden mobile-only drill paths.
                HeadmasterModuleDirectory(enabledModules: enabledModules),

                // KPI grid (2 per row).
                _MetricsGrid(metrics: data.metrics),
                const SizedBox(height: AppSpacing.stackLg),

                // Teacher attendance + analytics.
                if (_enabled('attendance')) ...[
                  const TeacherAttendanceReportCard(),
                  const SizedBox(height: AppSpacing.stackLg),
                ],

                // Pending approvals.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            AppIcons.assignmentLateOutlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SectionHeader(
                              title: 'Pending\nApprovals',
                              actionLabel: 'View All',
                              onAction: () =>
                                  Get.toNamed(HeadmasterRoutes.approvals),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      for (var i = 0; i < data.approvals.length; i++) ...[
                        PendingApprovalRow(
                          approval: data.approvals[i],
                          onApprove: () =>
                              controller.approve(data.approvals[i].id),
                          onReject: () =>
                              controller.reject(data.approvals[i].id),
                        ),
                        if (i != data.approvals.length - 1)
                          const SizedBox(height: AppSpacing.stackSm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // Recent announcements.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            AppIcons.campaignOutlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Recent\nAnnouncements',
                              style: AppTypography.titleLg,
                            ),
                          ),
                          _NewButton(onTap: onAnnouncements),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      for (var i = 0; i < data.announcements.length; i++) ...[
                        RecentAnnouncementRow(
                          item: data.announcements[i],
                          onTap: onAnnouncements,
                        ),
                        if (i != data.announcements.length - 1)
                          const SizedBox(height: AppSpacing.stackSm),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Maps a metric label (e.g. "Total Students") to the icon, color, listing
/// route, and — where the module supports it — an in-tab create trigger.
class _MetricMeta {
  final IconData icon;
  final Color color;
  final String? route;
  final String? createRoute;

  const _MetricMeta({
    required this.icon,
    required this.color,
    this.route,
    this.createRoute,
  });
}

_MetricMeta _metricMetaFor(String label) {
  final l = label.toLowerCase();
  if (l.contains('student')) {
    return _MetricMeta(
      icon: AppIcons.schoolRounded,
      color: AppColors.primary,
      route: HeadmasterRoutes.students,
      createRoute: HeadmasterRoutes.studentRegistration,
    );
  }
  if (l.contains('teacher')) {
    return _MetricMeta(
      icon: AppIcons.personOutlineRounded,
      color: const Color(0xFFF59E0B),
      route: HeadmasterRoutes.teachers,
      createRoute: HeadmasterRoutes.teacherRegistration,
    );
  }
  if (l.contains('class')) {
    return _MetricMeta(
      icon: AppIcons.classOutlined,
      color: AppColors.secondary,
      route: HeadmasterRoutes.classes,
    );
  }
  if (l.contains('subject')) {
    return _MetricMeta(
      icon: AppIcons.menuBookRounded,
      color: AppColors.tertiary,
      route: HeadmasterRoutes.coursesAdmin,
    );
  }
  return const _MetricMeta(
    icon: AppIcons.insightsRounded,
    color: AppColors.primary,
  );
}

class _MetricsGrid extends StatelessWidget {
  final List<DashboardMetric> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.stackMd;
        // 2 cards per row on a phone, 3 on a tablet, 4 on the web — otherwise the
        // fixed 2-up layout stretches each card unpleasantly wide.
        final cols = DashboardStatGrid.columnsFor(constraints.maxWidth);
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in metrics)
              SizedBox(
                width: width,
                child: Builder(
                  builder: (_) {
                    final meta = _metricMetaFor(m.label);
                    final decorated = DashboardMetric(
                      label: m.label,
                      value: m.value,
                      trendPercent: m.trendPercent,
                      icon: meta.icon,
                      color: meta.color,
                    );
                    return DashboardMetricCard(
                      metric: decorated,
                      onTap: meta.route == null
                          ? null
                          : () => Get.toNamed(meta.route!),
                      onAdd: (meta.createRoute ?? meta.route) == null
                          ? null
                          : () => Get.toNamed(meta.createRoute ?? meta.route!),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NewButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _NewButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.add, size: 14, color: AppColors.onPrimary),
              const SizedBox(width: 4),
              Text(
                'New',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prominent red banner shown on the Headmaster home when the school's
/// subscription is near or past expiry. Stays visible until the subscription is
/// renewed (moving its end date out) or fully lapses.
class _ExpiryAlert extends StatelessWidget {
  final SubscriptionStatus status;
  const _ExpiryAlert({required this.status});

  /// Only render for a real subscription that is expiring soon or expired.
  static bool shouldShow(SubscriptionStatus? s) =>
      s != null && s.hasSubscription && (s.isExpiringSoon || s.isExpired);

  String get _message {
    if (status.isExpired) {
      return 'Your subscription has expired. Please renew to restore access.';
    }
    final days = status.daysRemaining ?? 0;
    final unit = days == 1 ? 'day' : 'days';
    return 'Your subscription will expire in $days $unit. '
        'Please renew to avoid service interruption.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warningAmberRounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isExpired
                      ? 'Subscription expired'
                      : 'Subscription expiring soon',
                  style: AppTypography.titleMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_message, style: AppTypography.bodyMd),
                if (status.planName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Plan: ${status.planName}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
