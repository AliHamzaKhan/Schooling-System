import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../attendance/components/teacher_attendance_card.dart';
import '../components/dashboard_metric_card.dart';
import '../components/pending_approval_row.dart';
import '../components/recent_announcement_row.dart';
import '../controller/dashboard_controller.dart';
import '../models/dashboard_data.dart';

/// Headmaster Dashboard — greeting, daily KPIs, pending approvals, and a
/// preview of recent announcements with a quick "New" CTA.
class DashboardView extends GetView<DashboardController> {
  final VoidCallback? onAnnouncements;
  final VoidCallback? onSettings;
  final VoidCallback? onSalary;

  const DashboardView({
    super.key,
    this.onAnnouncements,
    this.onSettings,
    this.onSalary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalTopBar(onBell: onAnnouncements),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = controller.data.value;
            if (data == null) {
              return Center(
                  child: Text(controller.error.value ?? 'No data',
                      style: AppTypography.bodyLg));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text(data.greeting, style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text("Here's what's happening on campus today.",
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),

                // Admin quick actions.
                Row(
                  children: [
                    Expanded(
                      child: _AdminAction(
                        icon: Icons.settings_outlined,
                        label: 'School Settings',
                        onTap: onSettings,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: _AdminAction(
                        icon: Icons.payments_outlined,
                        label: 'Teacher Salaries',
                        onTap: onSalary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // KPI grid (2 per row).
                _MetricsGrid(metrics: data.metrics),
                const SizedBox(height: AppSpacing.stackLg),

                // Teacher attendance + analytics.
                const TeacherAttendanceReportCard(),
                const SizedBox(height: AppSpacing.stackLg),

                // Pending approvals.
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_late_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SectionHeader(
                              title: 'Pending\nApprovals',
                              actionLabel: 'View All',
                              onAction: () => Get.toNamed(
                                HeadmasterRoutes.approvals,
                                arguments: data.approvals,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      for (var i = 0; i < data.approvals.length; i++) ...[
                        PendingApprovalRow(
                          approval: data.approvals[i],
                          onApprove: () => controller.approve(data.approvals[i].id),
                          onReject: () => controller.reject(data.approvals[i].id),
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
                          const Icon(Icons.campaign_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Recent\nAnnouncements',
                                style: AppTypography.titleLg),
                          ),
                          _NewButton(onTap: onAnnouncements),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      for (var i = 0; i < data.announcements.length; i++) ...[
                        RecentAnnouncementRow(
                            item: data.announcements[i], onTap: onAnnouncements),
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
      icon: Icons.school_rounded,
      color: AppColors.primary,
      route: HeadmasterRoutes.students,
      createRoute: HeadmasterRoutes.studentRegistration,
    );
  }
  if (l.contains('teacher')) {
    return _MetricMeta(
      icon: Icons.person_outline_rounded,
      color: const Color(0xFFF59E0B),
      route: HeadmasterRoutes.teachers,
      createRoute: HeadmasterRoutes.teacherRegistration,
    );
  }
  if (l.contains('class')) {
    return _MetricMeta(
      icon: Icons.class_outlined,
      color: AppColors.secondary,
      route: HeadmasterRoutes.classes,
    );
  }
  if (l.contains('subject')) {
    return _MetricMeta(
      icon: Icons.menu_book_rounded,
      color: AppColors.tertiary,
      route: HeadmasterRoutes.classes,
    );
  }
  return const _MetricMeta(
    icon: Icons.insights_rounded,
    color: AppColors.primary,
  );
}

class _MetricsGrid extends StatelessWidget {
  final List<DashboardMetric> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = AppSpacing.stackMd;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final m in metrics)
            SizedBox(
              width: width,
              child: Builder(builder: (_) {
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
              }),
            ),
        ],
      );
    });
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _AdminAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text(label,
                  style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
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
              const Icon(Icons.add, size: 14, color: AppColors.onPrimary),
              const SizedBox(width: 4),
              Text('New',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
