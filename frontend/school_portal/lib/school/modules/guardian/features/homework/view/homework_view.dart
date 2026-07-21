import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/homework_controller.dart';
import '../models/homework_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Homework Tracking — pending/submitted counters and a per-child list of
/// assignments with status pills and grades when available.
class HomeworkView extends GetView<HomeworkController> {
  final VoidCallback? onNotifications;
  final VoidCallback? onManageChildren;
  const HomeworkView(
      {super.key, this.onNotifications, this.onManageChildren});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'Homework', onBell: onNotifications),
        ChildSwitcher(onManage: onManageChildren),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: SkeletonCardList(count: 5, height: 104));
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
                Row(
                  children: [
                    _CounterTile(
                        label: 'Pending',
                        value: d.pending,
                        color: const Color(0xFFE8A317)),
                    const SizedBox(width: AppSpacing.stackSm),
                    _CounterTile(
                        label: 'Submitted',
                        value: d.submitted,
                        color: AppColors.tertiary),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg),
                const SectionHeader(title: 'Assignments'),
                const SizedBox(height: AppSpacing.stackMd),
                for (final h in d.items) ...[
                  _HomeworkRow(item: h),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _CounterTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CounterTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
        child: Column(
          children: [
            Text('$value',
                style: AppTypography.displayLg
                    .copyWith(fontSize: 34, color: color)),
            Text(label, style: AppTypography.bodyMd),
          ],
        ),
      ),
    );
  }
}

class _HomeworkRow extends StatelessWidget {
  final HomeworkItem item;
  const _HomeworkRow({required this.item});

  ({String label, Color color}) get _style => switch (item.status) {
        HomeworkStatus.pending => (label: 'Pending', color: Color(0xFFE8A317)),
        HomeworkStatus.submitted =>
          (label: 'Submitted', color: AppColors.primary),
        HomeworkStatus.graded => (label: 'Graded', color: AppColors.tertiary),
        HomeworkStatus.overdue => (label: 'Overdue', color: AppColors.error),
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subject.toUpperCase(),
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(item.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Due ${item.dueDate}', style: AppTypography.bodyMd),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: s.label, color: s.color),
              if (item.grade != null) ...[
                const SizedBox(height: 6),
                Text(item.grade!,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
