import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_search_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/attendance_student_row.dart';
import '../controller/attendance_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Attendance Marking — class header, totals row, mark-all CTA + search, then
/// the student list. Submit FAB pops a result.
class AttendanceMarkView extends GetView<AttendanceMarkController> {
  const AttendanceMarkView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          PortalTopBar(title: 'Teacher Portal', onBell: () => Get.back<void>()),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(withHeader: false, body: SkeletonRosterList());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    140),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: controller.classInfo.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: controller.classInfo.color,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(controller.classInfo.subject,
                                style: AppTypography.labelMd.copyWith(
                                    color: controller.classInfo.color,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(controller.classInfo.grade,
                      style: AppTypography.headlineLg),
                  const SizedBox(height: AppSpacing.stackSm),
                  Row(
                    children: [
                      const Icon(AppIcons.calendarTodayOutlined,
                          size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Oct 24, 2023', style: AppTypography.bodyMd),
                      const Spacer(),
                      _MarkAllPresentButton(onTap: controller.markAllPresent),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  _TotalsCard(controller: controller),
                  const SizedBox(height: AppSpacing.stackLg),
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PortalSearchField(
                          hint: 'Search…',
                          onChanged: controller.onSearch,
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        for (final s in controller.filtered) ...[
                          AttendanceStudentRow(
                            student: s,
                            mark: controller.markFor(s.id),
                            onChanged: (m) => controller.setMark(s.id, m),
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4),
        child: FloatingActionButton.extended(
          onPressed: controller.submit,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          icon: const Icon(AppIcons.sendRounded),
          label: const Text('Submit Attendance'),
        ),
      ),
    );
  }
}

/// Compact pill CTA that marks every student present. Lives in the class
/// header (top-right, beside the date) so the search field can span full width.
class _MarkAllPresentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MarkAllPresentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.doneAllRounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Mark All Present',
                style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final AttendanceMarkController controller;
  const _TotalsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackLg, vertical: AppSpacing.stackMd),
      child: Row(
        children: [
          _Tally(label: 'TOTAL', value: '${controller.total}', color: AppColors.primary),
          const _VDivider(),
          _Tally(label: 'PRESENT', value: '${controller.present}', color: AppColors.tertiary),
          const _VDivider(),
          _Tally(label: 'ABSENT', value: '${controller.absent}', color: AppColors.error),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Tally({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.displayLg.copyWith(fontSize: 28, color: color)),
          Text(label,
              style: AppTypography.labelCaps.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.outlineVariant);
}
