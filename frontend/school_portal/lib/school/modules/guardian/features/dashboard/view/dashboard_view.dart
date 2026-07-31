import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/guardian_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../shared/controller/guardian_session_controller.dart';
import '../../../shared/models/child.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../components/activity_timeline.dart';
import '../components/summary_card.dart';
import '../controller/dashboard_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Guardian Dashboard — multi-child switcher, per-child summary cards, quick
/// links to drill-in screens, and a timeline-based activity feed.
class GuardianDashboardView extends GetView<GuardianDashboardController> {
  final VoidCallback? onNotifications;
  final VoidCallback? onManageChildren;
  final VoidCallback? onOpenFees;
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenMeetings;
  final VoidCallback? onOpenReportCard;
  final VoidCallback? onOpenTimetable;

  const GuardianDashboardView({
    super.key,
    this.onNotifications,
    this.onManageChildren,
    this.onOpenFees,
    this.onOpenExams,
    this.onOpenMeetings,
    this.onOpenReportCard,
    this.onOpenTimetable,
  });

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    return Column(
      children: [
        PortalTopBar(title: 'EduMaster', hasUnread: true, onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (session.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 4), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3)]));
            }
            final child = session.selected;
            if (child == null) {
              return Center(
                child: Text('No children linked to this account.',
                    style: AppTypography.bodyLg),
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackXl),
              children: [
                const SizedBox(height: AppSpacing.stackSm),
                ChildSwitcher(onManage: onManageChildren),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPaddingMobile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChildHeader(name: child.name, grade: child.grade),
                      const SizedBox(height: AppSpacing.stackLg),
                      _SummaryGrid(
                        child: child,
                        onOpenFees: onOpenFees,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      GlassSurface(
                        onTap: () => Get.toNamed(GuardianRoutes.leave),
                        padding: const EdgeInsets.all(AppSpacing.stackLg),
                        child: Row(
                          children: [
                            const Icon(Icons.event_busy_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: AppSpacing.stackMd),
                            Expanded(
                              child: Text('Leave Application',
                                  style: AppTypography.titleMd
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.onSurfaceVariant),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      _QuickLinks(
                        onOpenExams: onOpenExams,
                        onOpenMeetings: onOpenMeetings,
                        onOpenFees: onOpenFees,
                        onOpenReportCard: onOpenReportCard,
                        onOpenTimetable: onOpenTimetable,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      const SectionHeader(title: 'Recent Activity'),
                      const SizedBox(height: AppSpacing.stackMd),
                      Obx(() {
                        if (controller.loadingFeed.value) {
                          return const Shimmer(
                            child: SkeletonCardList(count: 3, height: 56),
                          );
                        }
                        return ActivityTimeline(items: controller.feed);
                      }),
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

class _ChildHeader extends StatelessWidget {
  final String name;
  final String grade;
  const _ChildHeader({required this.name, required this.grade});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<GuardianSessionController>();
    final child = session.selected!;
    return Row(
      children: [
        ChildAvatar(child: child, size: 52),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.headlineLg.copyWith(fontSize: 24)),
              Text(grade, style: AppTypography.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Child child;
  final VoidCallback? onOpenFees;
  const _SummaryGrid({required this.child, this.onOpenFees});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.stackMd,
      crossAxisSpacing: AppSpacing.stackMd,
      childAspectRatio: 1.35,
      children: [
        SummaryCard(
          icon: Icons.event_available_rounded,
          accent: AppColors.tertiary,
          label: 'Attendance',
          value: '${child.attendancePercent}%',
          sub: 'This month',
        ),
        SummaryCard(
          icon: Icons.grading_rounded,
          accent: AppColors.primary,
          label: 'GPA',
          value: child.gpa.toStringAsFixed(1),
          sub: 'Term average',
        ),
        SummaryCard(
          icon: Icons.assignment_outlined,
          accent: const Color(0xFFE8A317),
          label: 'Pending homework',
          value: '${child.pendingHomework}',
          sub: child.pendingHomework == 0 ? 'All clear' : 'Due soon',
        ),
        SummaryCard(
          icon: Icons.payments_outlined,
          accent: child.feesDue ? AppColors.error : AppColors.tertiary,
          label: 'Fees',
          value: child.feesDue ? 'Due' : 'Paid',
          sub: child.feesDue ? 'Tap to view' : 'Up to date',
          onTap: onOpenFees,
        ),
      ],
    );
  }
}

class _QuickLinks extends StatelessWidget {
  final VoidCallback? onOpenExams;
  final VoidCallback? onOpenMeetings;
  final VoidCallback? onOpenFees;
  final VoidCallback? onOpenReportCard;
  final VoidCallback? onOpenTimetable;
  const _QuickLinks({
    this.onOpenExams,
    this.onOpenMeetings,
    this.onOpenFees,
    this.onOpenReportCard,
    this.onOpenTimetable,
  });

  @override
  Widget build(BuildContext context) {
    final links = <Widget>[
      _LinkChip(
          icon: Icons.grading_rounded,
          label: 'Report Card',
          onTap: onOpenReportCard),
      _LinkChip(
          icon: Icons.calendar_month_outlined,
          label: 'Timetable',
          onTap: onOpenTimetable),
      _LinkChip(
          icon: Icons.school_outlined, label: 'Exams', onTap: onOpenExams),
      _LinkChip(
          icon: Icons.groups_outlined,
          label: 'Meetings',
          onTap: onOpenMeetings),
      _LinkChip(
          icon: Icons.payments_outlined, label: 'Fees', onTap: onOpenFees),
    ];
    // Two rows: a top row of 3 then a bottom row of the rest, each chip flexing.
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.stackSm),
              links[i],
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Row(
          children: [
            for (var i = 3; i < links.length; i++) ...[
              if (i > 3) const SizedBox(width: AppSpacing.stackSm),
              links[i],
            ],
            // keep the last row aligned to the same chip width as the top row
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _LinkChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.labelMd),
            ],
          ),
        ),
      ),
    );
  }
}
