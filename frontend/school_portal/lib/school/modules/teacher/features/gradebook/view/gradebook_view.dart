import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/mark_entry_row.dart';
import '../controller/gradebook_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Marks Entry / Gradebook — breadcrumb + exam title, Export CSV, scrollable
/// list of student rows with Obtained inputs, and a sticky footer showing the
/// running class average and Save All Marks button.
class GradebookView extends GetView<GradebookController> {
  const GradebookView({super.key});

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
              final book = controller.book.value;
              // No paper chosen yet — offer the real list of papers rather
              // than a blank screen.
              if (book == null) return _PaperPicker(controller: controller);
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.menuBookOutlined,
                          size: 16, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(book.breadcrumb,
                            style: AppTypography.bodyMd,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(book.examTitle,
                      style: AppTypography.displayLg.copyWith(fontSize: 32)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text(
                    'Enter marks for ${book.totalStudents} students. '
                    'Total marks available: ${book.totalMarks}.',
                    style: AppTypography.bodyLg,
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GhostButton(
                      label: 'Export CSV',
                      leadingIcon: AppIcons.downloadRounded,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final s in book.students)
                    MarkEntryRow(
                      // Each student keeps their own row State (and its field
                      // controller) across rebuilds and paper switches.
                      key: ValueKey(s.id),
                      student: s,
                      totalMarks: book.totalMarks,
                      obtained: controller.marks[s.id],
                      onChanged: (v) => controller.setMark(s.id, v),
                      onOpenStudent: () => Get.toNamed(
                        TeacherRoutes.studentPerformance,
                        arguments: s.id,
                      ),
                    ),
                ],
              );
            }),
          ),
          _Footer(controller: controller),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final GradebookController controller;
  const _Footer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Icon(AppIcons.barChartRounded,
                  color: AppColors.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Obx(() {
                final book = controller.book.value;
                if (book == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class Average:', style: AppTypography.bodyMd),
                    Text('${controller.classAveragePercent}%',
                        style: AppTypography.titleLg
                            .copyWith(fontWeight: FontWeight.w800)),
                    Text(
                        '${controller.entered} of ${book.totalStudents} entered',
                        style: AppTypography.bodySm),
                  ],
                );
              }),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Obx(() => PrimaryButton(
                  label: 'Save All\nMarks',
                  leadingIcon: AppIcons.saveOutlined,
                  trailingIcon: null,
                  isLoading: controller.saving.value,
                  onPressed: controller.saveAll,
                )),
          ],
        ),
      ),
    );
  }
}


/// Shown until a paper is chosen. Lists real exam papers; an empty list means
/// the school genuinely has no papers set up yet.
class _PaperPicker extends StatelessWidget {
  final GradebookController controller;
  const _PaperPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final err = controller.error.value;
      final papers = controller.papers;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            0,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          Text('Marks Entry',
              style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Choose an exam paper to grade.', style: AppTypography.bodyLg),
          const SizedBox(height: AppSpacing.stackLg),
          if (err != null)
            _Empty(
              icon: AppIcons.cloudOffRounded,
              text: err,
              onRetry: controller.loadPapers,
            )
          else if (papers.isEmpty)
            const _Empty(
              icon: AppIcons.factCheckOutlined,
              text: 'No exam papers have been set up yet.',
            )
          else
            for (final p in papers) ...[
              GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                onTap: () => controller.selectPaper(p.paperId),
                child: Row(
                  children: [
                    const Icon(AppIcons.menuBookOutlined,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMd
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text('Out of ${p.maxMarks.toStringAsFixed(0)}',
                              style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                    const Icon(AppIcons.chevronRightRounded,
                        color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
            ],
        ],
      );
    });
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  const _Empty({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackXl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackMd),
          Text(text, style: AppTypography.bodyLg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
