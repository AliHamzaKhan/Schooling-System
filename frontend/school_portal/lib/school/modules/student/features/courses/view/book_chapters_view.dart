import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../../../../widgets/skeletons.dart';
import '../controller/book_chapters_controller.dart';
import '../controller/reader_controller.dart';
import '../models/course_models.dart';

/// The Book track: a table of contents. Picking a chapter opens the reader; a
/// "Continue reading" shortcut jumps to the last chapter the student was on.
class BookChaptersView extends GetView<BookChaptersController> {
  const BookChaptersView({super.key});

  void _openReader(ChapterBrief chapter) {
    final book = controller.selectedBook.value!;
    Get.toNamed(
      StudentRoutes.courseReader,
      arguments: ReaderArgs.book(
        bookId: book.id,
        bookTitle: book.title,
        chapters: controller.chapters.toList(),
        initialChapterId: chapter.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Book')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 6, height: 64));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final book = controller.selectedBook.value;
        if (book == null || controller.chapters.isEmpty) {
          return Center(
              child: Text('No chapters yet.', style: AppTypography.bodyLg));
        }
        final resume = controller.resumeChapter;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            Text(book.title, style: AppTypography.headlineLg),
            if ((book.description ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Text(book.description!, style: AppTypography.bodyLg),
            ],
            const SizedBox(height: AppSpacing.stackLg),

            // Book switcher (only when the course has more than one book).
            if (controller.books.length > 1) ...[
              Wrap(
                spacing: AppSpacing.stackSm,
                runSpacing: AppSpacing.stackSm,
                children: [
                  for (final b in controller.books)
                    ChoiceChip(
                      label: Text(b.title),
                      selected: b.id == book.id,
                      onSelected: (_) => controller.selectBook(b),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],

            if (resume != null) ...[
              PrimaryButton(
                label: 'Continue: ${resume.title}',
                leadingIcon: AppIcons.playArrowRounded,
                expanded: true,
                onPressed: () => _openReader(resume),
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],

            Text('Chapters',
                style: AppTypography.titleMd
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.stackMd),
            for (var i = 0; i < controller.chapters.length; i++) ...[
              _ChapterRow(
                index: i + 1,
                title: controller.chapters[i].title,
                onTap: () => _openReader(controller.chapters[i]),
              ),
              const SizedBox(height: AppSpacing.stackSm),
            ],
          ],
        );
      }),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final int index;
  final String title;
  final VoidCallback onTap;
  const _ChapterRow(
      {required this.index, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text('$index',
                style: AppTypography.labelMd
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(child: Text(title, style: AppTypography.bodyLg)),
          const Icon(AppIcons.chevronRightRounded,
              color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
