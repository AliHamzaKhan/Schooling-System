import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../controller/attendance_controller.dart';
import '../models/attendance_models.dart';
import '../../../../../widgets/skeletons.dart';

/// Attendance tab — pick a class to take attendance for, then drill into the
/// marking screen.
class AttendanceClassesView extends GetView<TeacherAttendanceController> {
  const AttendanceClassesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalTopBar(title: 'Teacher Portal'),
        Expanded(
          child: Obx(() {
            if (controller.loading.value) {
              return const SkeletonPage(body: SkeletonCardList(count: 4, height: 96));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('Attendance', style: AppTypography.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Pick a class to take today\'s attendance.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                for (final c in controller.classes) ...[
                  _ClassRow(
                    item: c,
                    onTap: () => Get.toNamed(
                      TeacherRoutes.attendanceMark,
                      arguments: c,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  final AttendanceClass item;
  final VoidCallback onTap;
  const _ClassRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subject,
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
                Text('${item.grade} · ${item.students} students',
                    style: AppTypography.bodyMd),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRightRounded, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
