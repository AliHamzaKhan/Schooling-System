import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/attendance_controller.dart';
import '../models/attendance_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Attendance Tracking — per-child monthly summary, present/absent/late
/// breakdown, and a report-style list of recent daily records.
class GuardianAttendanceView extends GetView<GuardianAttendanceController> {
  final VoidCallback? onNotifications;
  final VoidCallback? onManageChildren;
  const GuardianAttendanceView(
      {super.key, this.onNotifications, this.onManageChildren});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'Attendance', onBell: onNotifications),
        ChildSwitcher(onManage: onManageChildren),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 4, height: 76)]));
            }
            final d = controller.data.value;
            if (d == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackSm,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                _MonthlyCard(percent: d.monthlyPercent),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    _BreakdownTile(
                        label: 'Present',
                        value: d.presentDays,
                        color: AppColors.tertiary),
                    const SizedBox(width: AppSpacing.stackSm),
                    _BreakdownTile(
                        label: 'Absent',
                        value: d.absentDays,
                        color: AppColors.error),
                    const SizedBox(width: AppSpacing.stackSm),
                    _BreakdownTile(
                        label: 'Late',
                        value: d.lateDays,
                        color: const Color(0xFFE8A317)),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                const SectionHeader(title: 'Recent Records'),
                const SizedBox(height: AppSpacing.stackMd),
                GlassSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < d.recent.length; i++)
                        _RecordRow(
                            record: d.recent[i],
                            isLast: i == d.recent.length - 1),
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

class _MonthlyCard extends StatelessWidget {
  final int percent;
  const _MonthlyCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Attendance', style: AppTypography.bodyLg),
                const SizedBox(height: 4),
                Text('$percent%',
                    style: AppTypography.displayLg.copyWith(fontSize: 40)),
              ],
            ),
          ),
          StatusPill(
            label: percent >= 90 ? 'On track' : 'Needs attention',
            color: percent >= 90 ? AppColors.tertiary : const Color(0xFFE8A317),
            icon: Icons.insights_rounded,
          ),
        ],
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BreakdownTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
        child: Column(
          children: [
            Text('$value',
                style: AppTypography.headlineLg
                    .copyWith(fontSize: 26, color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelMd),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AttendanceRecord record;
  final bool isLast;
  const _RecordRow({required this.record, required this.isLast});

  ({String label, Color color, IconData icon}) get _style =>
      switch (record.status) {
        AttendanceStatus.present => (
            label: 'Present',
            color: AppColors.tertiary,
            icon: Icons.check_circle_outline_rounded
          ),
        AttendanceStatus.absent => (
            label: 'Absent',
            color: AppColors.error,
            icon: Icons.cancel_outlined
          ),
        AttendanceStatus.late => (
            label: 'Late',
            color: const Color(0xFFE8A317),
            icon: Icons.schedule_rounded
          ),
        AttendanceStatus.holiday => (
            label: 'Holiday',
            color: AppColors.onSurfaceVariant,
            icon: Icons.beach_access_outlined
          ),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(s.icon, size: 20, color: s.color),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if (record.note != null)
                  Text(record.note!, style: AppTypography.bodyMd),
              ],
            ),
          ),
          StatusPill(label: s.label, color: s.color),
        ],
      ),
    );
  }
}
