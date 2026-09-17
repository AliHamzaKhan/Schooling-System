import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/headmaster_routes.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/course_content_controller.dart';

/// Headmaster: one course's content — its books and notes, with add actions.
class CourseContentView extends GetView<CourseContentController> {
  const CourseContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.course.value?.title ?? 'Course Content'),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(
            body: SkeletonCardList(count: 4, height: 72),
          );
        }
        if (controller.error.value != null) {
          return AppStateView.error(
            title: 'Could not load course content',
            message: controller.error.value!,
            actionLabel: controller.courseId.isEmpty ? null : 'Try again',
            onAction: controller.courseId.isEmpty ? null : controller.load,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXxl,
            ),
            children: [
              // Books.
              _SectionHeader(
                icon: AppIcons.autoStoriesRounded,
                title: 'Books',
                actionLabel: 'Add Book',
                onAction: controller.addBookFlow,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              if (controller.books.isEmpty)
                _EmptyLine(text: 'No books yet.')
              else
                for (final b in controller.books) ...[
                  GlassSurface(
                    onTap: () => Get.toNamed(
                      HeadmasterRoutes.bookAdmin,
                      parameters: {
                        'course_id': controller.courseId,
                        'book_id': b.id,
                      },
                    ),
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.bookOutlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.title, style: AppTypography.bodyLg),
                              Text(
                                '${b.chapterCount} '
                                '${b.chapterCount == 1 ? 'chapter' : 'chapters'}',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          AppIcons.chevronRightRounded,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
              const SizedBox(height: AppSpacing.stackLg),

              // Notes.
              _SectionHeader(
                icon: AppIcons.stickyNote2Outlined,
                title: 'Notes',
                actionLabel: 'Add Note',
                onAction: controller.addNoteFlow,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              if (controller.notes.isEmpty)
                _EmptyLine(text: 'No notes yet.')
              else
                for (final n in controller.notes) ...[
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.descriptionOutlined,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(
                          child: Text(n.title, style: AppTypography.bodyLg),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(AppIcons.addRounded, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
    );
  }
}
