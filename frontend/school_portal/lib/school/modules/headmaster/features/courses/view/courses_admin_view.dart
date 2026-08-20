import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/courses_admin_controller.dart';
import '../models/admin_course_models.dart';

/// Headmaster: manage the school's courses (create + drill into content).
class CoursesAdminView extends GetView<CoursesAdminController> {
  const CoursesAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Manage Courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.createFlow,
        icon: const Icon(AppIcons.addRounded),
        label: const Text('New Course'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 96));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.courses.isEmpty) {
          return Center(
              child: Text('No courses yet.\nTap “New Course” to add one.',
                  textAlign: TextAlign.center, style: AppTypography.bodyLg));
        }
        final groups = controller.grouped;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            children: [
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.stackSm, bottom: AppSpacing.stackSm),
                  child: Text(entry.key,
                      style: AppTypography.labelCaps
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ),
                for (final c in entry.value) ...[
                  _CourseCard(course: c),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
              ],
            ],
          ),
        );
      }),
    );
  }
}

/// One course row inside a class+section group. Shows the subject it teaches and
/// its book/note counts; taps into the content editor.
class _CourseCard extends StatelessWidget {
  final AdminCourse course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      if (course.subjectName != null || course.subject != null)
        (course.subjectName ?? course.subject)!,
      '${course.bookCount} ${course.bookCount == 1 ? 'book' : 'books'}',
      '${course.noteCount} ${course.noteCount == 1 ? 'note' : 'notes'}',
    ].join(' · ');
    return GlassSurface(
      onTap: () =>
          Get.toNamed(HeadmasterRoutes.courseContent, arguments: course),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Row(
        children: [
          const Icon(AppIcons.menuBookRounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRightRounded,
              color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
