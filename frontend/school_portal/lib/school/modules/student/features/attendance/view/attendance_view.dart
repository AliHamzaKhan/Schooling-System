import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../components/monthly_average_card.dart';
import '../controller/attendance_controller.dart';
import '../models/attendance_data.dart';
import '../../../../../widgets/skeletons.dart';

/// My Attendance — a circular monthly-average ring, a weekly multi-line status
/// chart, then Recent Absences and Late Arrivals cards.
class AttendanceView extends GetView<StudentAttendanceController> {
  final VoidCallback? onNotifications;
  const AttendanceView({super.key, this.onNotifications});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_months[now.month - 1]} ${now.year}';
    return Column(
      children: [
        PortalTopBar(title: 'Meri Taleem', onBell: onNotifications),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 4, height: 76)]));
            }
            final data = controller.data.value;
            if (data == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('Attendance Overview', style: AppTypography.displayLg.copyWith(fontSize: 32)),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Track your presence and punctuality.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                AttendanceRingCard(
                  percent: data.monthlyAverage,
                  delta: data.deltaPercent,
                  monthLabel: monthLabel,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                WeeklyStatusCard(week: data.week),
                const SizedBox(height: AppSpacing.stackLg),
                _RecentAbsencesCard(absences: data.recentAbsences),
                const SizedBox(height: AppSpacing.stackLg),
                _LateArrivalsCard(marks: data.lateMarks),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Card header: colored icon chip, title, and a muted "View All" affordance.
class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool showViewAll;
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.showViewAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(
          child: Text(title,
              style: AppTypography.headlineLg.copyWith(fontSize: 20)),
        ),
        if (showViewAll)
          Text('View All',
              style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RecentAbsencesCard extends StatelessWidget {
  final List<String> absences;
  const _RecentAbsencesCard({required this.absences});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: AppIcons.eventBusyOutlined,
            title: 'Recent Absences',
            color: kAttendAbsent,
            showViewAll: absences.length > 3,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          if (absences.isEmpty)
            _EmptyPanel(
              icon: AppIcons.sentimentSatisfiedAltOutlined,
              title: 'Perfect Streak!',
              subtitle: 'No absences recorded recently.',
            )
          else
            for (final date in absences.take(4)) ...[
              _AbsenceRow(date: date),
              const SizedBox(height: AppSpacing.stackSm),
            ],
        ],
      ),
    );
  }
}

class _AbsenceRow extends StatelessWidget {
  final String date;
  const _AbsenceRow({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kAttendAbsent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.calendarTodayOutlined,
                size: 17, color: kAttendAbsent),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Text(date,
                style: AppTypography.titleMd
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          _Pill(label: 'Absent', color: kAttendAbsent),
        ],
      ),
    );
  }
}

class _LateArrivalsCard extends StatelessWidget {
  final List<LateMark> marks;
  const _LateArrivalsCard({required this.marks});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: AppIcons.scheduleRounded,
            title: 'Late Arrivals',
            color: kAttendLate,
            showViewAll: marks.length > 3,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          if (marks.isEmpty)
            _EmptyPanel(
              icon: AppIcons.verifiedOutlined,
              title: 'Always On Time',
              subtitle: 'No late marks recorded recently.',
            )
          else
            for (final m in marks.take(4)) ...[
              _MarkRow(mark: m),
              const SizedBox(height: AppSpacing.stackSm),
            ],
        ],
      ),
    );
  }
}

class _MarkRow extends StatelessWidget {
  final LateMark mark;
  const _MarkRow({required this.mark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kAttendLate.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.scheduleRounded,
                size: 17, color: kAttendLate),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mark.date,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if (mark.period.isNotEmpty)
                  Text(mark.period, style: AppTypography.bodyMd),
              ],
            ),
          ),
          if (mark.minutes > 0)
            _Pill(label: '${mark.minutes} mins', color: kAttendLate),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.labelMd
              .copyWith(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: kAttendPresent),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(title,
              style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w800)),
          Text(subtitle, style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}
