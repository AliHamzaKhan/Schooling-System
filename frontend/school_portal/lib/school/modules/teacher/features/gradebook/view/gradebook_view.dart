import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../components/mark_entry_row.dart';
import '../controller/gradebook_controller.dart';

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
                return const Center(child: CircularProgressIndicator());
              }
              final book = controller.book.value;
              if (book == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
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
                      leadingIcon: Icons.download_rounded,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  for (final s in book.students)
                    MarkEntryRow(
                      student: s,
                      totalMarks: book.totalMarks,
                      controller: controller.controllerFor(s.id),
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
              child: const Icon(Icons.bar_chart_rounded,
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
                  leadingIcon: Icons.save_outlined,
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
