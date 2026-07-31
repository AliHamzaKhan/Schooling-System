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
      appBar: AppBar(title: Text(controller.course.title)),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 72));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackLg,
                AppSpacing.containerPaddingMobile,
                AppSpacing.stackXxl),
            children: [
              // Books.
              _SectionHeader(
                icon: Icons.auto_stories_rounded,
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
                    onTap: () =>
                        Get.toNamed(HeadmasterRoutes.bookAdmin, arguments: b),
                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                    child: Row(
                      children: [
                        const Icon(Icons.book_outlined, color: AppColors.primary),
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
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
              const SizedBox(height: AppSpacing.stackLg),

              // Notes.
              _SectionHeader(
                icon: Icons.sticky_note_2_outlined,
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
                        const Icon(Icons.description_outlined,
                            color: AppColors.tertiary),
                        const SizedBox(width: AppSpacing.stackMd),
                        Expanded(child: Text(n.title, style: AppTypography.bodyLg)),
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
        Text(title,
            style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded, size: 18),
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
    return Text(text,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant));
  }
}
