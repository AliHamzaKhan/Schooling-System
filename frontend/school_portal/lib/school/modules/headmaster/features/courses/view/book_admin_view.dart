import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/book_admin_controller.dart';

/// Headmaster: one book's chapters — list and add.
class BookAdminView extends GetView<BookAdminController> {
  const BookAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.book.value?.title ?? 'Book Chapters')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.addChapterFlow,
        icon: const Icon(AppIcons.addRounded),
        label: const Text('Add Chapter'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(
            body: SkeletonCardList(count: 5, height: 60),
          );
        }
        if (controller.error.value != null) {
          return AppStateView.error(
            title: 'Could not load book chapters',
            message: controller.error.value!,
            actionLabel: controller.bookId.isEmpty ? null : 'Try again',
            onAction: controller.bookId.isEmpty ? null : controller.load,
          );
        }
        if (controller.chapters.isEmpty) {
          return Center(
            child: Text(
              'No chapters yet.\nTap “Add Chapter” to start.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXxl,
            ),
            itemCount: controller.chapters.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackSm),
            itemBuilder: (_, i) {
              final ch = controller.chapters[i];
              return GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Expanded(
                      child: Text(ch.title, style: AppTypography.bodyLg),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
