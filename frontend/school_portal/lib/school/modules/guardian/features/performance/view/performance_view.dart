import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/performance_controller.dart';
import '../models/performance_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Academic Performance — GPA + class rank headline, subject-by-subject grade
/// report with term-over-term trend pills. Clean report-style layout.
class PerformanceView extends GetView<GuardianPerformanceController> {
  final VoidCallback? onNotifications;
  final VoidCallback? onManageChildren;
  const PerformanceView(
      {super.key, this.onNotifications, this.onManageChildren});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalTopBar(title: 'Performance', onBell: onNotifications),
        ChildSwitcher(onManage: onManageChildren),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 2, height: 170)]));
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
                _HeadlineCard(data: d),
                const SizedBox(height: AppSpacing.stackLg),
                SectionHeader(title: 'Subjects', actionLabel: d.termLabel),
                const SizedBox(height: AppSpacing.stackMd),
                for (final s in d.subjects) ...[
                  _SubjectRow(grade: s),
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

class _HeadlineCard extends StatelessWidget {
  final PerformanceData data;
  const _HeadlineCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall', style: AppTypography.bodyLg),
                Text('${data.averagePercent.round()}%',
                    style: AppTypography.displayLg.copyWith(fontSize: 40)),
              ],
            ),
          ),
          Container(width: 1, height: 56, color: AppColors.outlineVariant),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest exam', style: AppTypography.bodyLg),
                Text(data.termLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectGrade grade;
  const _SubjectRow({required this.grade});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Text(grade.grade,
                style: AppTypography.titleMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(grade.subject,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: grade.percent / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${grade.percent}%',
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              if (grade.deltaPercent != null)
                StatusPill.trend(grade.deltaPercent!),
            ],
          ),
        ],
      ),
    );
  }
}
