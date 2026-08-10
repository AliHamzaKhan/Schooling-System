import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/guardian_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../shared/models/child.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../../../../../widgets/dashboard_kit.dart';
import '../components/activity_timeline.dart';
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
  final VoidCallback? onOpenMessages;

  const GuardianDashboardView({
    super.key,
    this.onNotifications,
    this.onManageChildren,
    this.onOpenFees,
    this.onOpenExams,
    this.onOpenMeetings,
    this.onOpenReportCard,
    this.onOpenTimetable,
    this.onOpenMessages,
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
                      DashboardIdentityCard(
                        title: child.name,
                        subtitle: child.grade,
                        leading: ChildAvatar(child: child, size: 56),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      _SummaryGrid(
                        child: child,
                        onOpenFees: onOpenFees,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      DashboardPrimaryAction(
                        icon: Icons.event_busy_rounded,
                        label: 'Leave Application',
                        onTap: () => Get.toNamed(GuardianRoutes.leave),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      _QuickLinks(
                        onOpenExams: onOpenExams,
                        onOpenMeetings: onOpenMeetings,
                        onOpenFees: onOpenFees,
                        onOpenReportCard: onOpenReportCard,
                        onOpenTimetable: onOpenTimetable,
                        onOpenMessages: onOpenMessages,
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

class _SummaryGrid extends StatelessWidget {
  final Child child;
  final VoidCallback? onOpenFees;
  const _SummaryGrid({required this.child, this.onOpenFees});

  @override
  Widget build(BuildContext context) {
    return DashboardStatGrid(
      stats: [
        DashboardStat(
          icon: Icons.event_available_rounded,
          accent: AppColors.tertiary,
          label: 'Attendance',
          value: '${child.attendancePercent}%',
          sub: 'This month',
        ),
        DashboardStat(
          icon: Icons.grading_rounded,
          accent: AppColors.primary,
          label: 'GPA',
          value: child.gpa.toStringAsFixed(1),
          sub: 'Term average',
        ),
        DashboardStat(
          icon: Icons.assignment_outlined,
          accent: const Color(0xFFE8A317),
          label: 'Pending homework',
          value: '${child.pendingHomework}',
          sub: child.pendingHomework == 0 ? 'All clear' : 'Due soon',
        ),
        DashboardStat(
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
  final VoidCallback? onOpenMessages;
  const _QuickLinks({
    this.onOpenExams,
    this.onOpenMeetings,
    this.onOpenFees,
    this.onOpenReportCard,
    this.onOpenTimetable,
    this.onOpenMessages,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardQuickLinks(
      links: [
        DashboardLink(
            icon: Icons.grading_rounded,
            label: 'Report Card',
            onTap: onOpenReportCard),
        DashboardLink(
            icon: Icons.calendar_month_outlined,
            label: 'Timetable',
            onTap: onOpenTimetable),
        DashboardLink(
            icon: Icons.school_outlined, label: 'Exams', onTap: onOpenExams),
        DashboardLink(
            icon: Icons.groups_outlined,
            label: 'Meetings',
            onTap: onOpenMeetings),
        DashboardLink(
            icon: Icons.payments_outlined, label: 'Fees', onTap: onOpenFees),
        DashboardLink(
            icon: Icons.forum_outlined,
            label: 'Messages',
            onTap: onOpenMessages),
      ],
    );
  }
}
