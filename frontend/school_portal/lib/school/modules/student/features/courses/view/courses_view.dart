import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/courses_controller.dart';
import '../models/course_models.dart';

/// Courses listing — every course available to the student, each opening into
/// its Book and Notes reading tracks.
class CoursesView extends GetView<CoursesController> {
  const CoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 108));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.courses.isEmpty) {
          return Center(
              child: Text('No courses available yet.',
                  style: AppTypography.bodyLg));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackMd,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXl),
            itemCount: controller.courses.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (_, i) => _CourseCard(course: controller.courses[i]),
          ),
        );
      }),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: () =>
          Get.toNamed(StudentRoutes.courseDetail, arguments: course),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    if ((course.subject ?? '').isNotEmpty)
                      Text(course.subject!,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant),
            ],
          ),
          if ((course.description ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Text(course.description!,
                style: AppTypography.bodyMd, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              _MetaPill(
                  icon: Icons.auto_stories_rounded,
                  label: '${course.bookCount} '
                      '${course.bookCount == 1 ? 'book' : 'books'}'),
              const SizedBox(width: AppSpacing.stackSm),
              _MetaPill(
                  icon: Icons.sticky_note_2_outlined,
                  label: '${course.noteCount} '
                      '${course.noteCount == 1 ? 'note' : 'notes'}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
