import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../components/dashboard_metric_card.dart';
import '../components/pending_approval_row.dart';
import '../components/recent_announcement_row.dart';
import '../controller/dashboard_controller.dart';

/// Headmaster Dashboard — greeting, daily KPIs, pending approvals, and a
/// preview of recent announcements with a quick "New" CTA.
class DashboardView extends GetView<DashboardController> {
  final VoidCallback? onAnnouncements;
  final VoidCallback? onSchoolOverview;

  const DashboardView({super.key, this.onAnnouncements, this.onSchoolOverview});

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
                const SizedBox(height: AppSpacing.stackMd),
                GestureDetector(
                  onTap: onSchoolOverview,
                  child: _DatePill(label: data.date),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                // KPI stack.
                for (final m in data.metrics) ...[
                  DashboardMetricCard(metric: m),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                const SizedBox(height: AppSpacing.stackSm),

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
                              onAction: () {},
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

class _DatePill extends StatelessWidget {
  final String label;
  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
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
