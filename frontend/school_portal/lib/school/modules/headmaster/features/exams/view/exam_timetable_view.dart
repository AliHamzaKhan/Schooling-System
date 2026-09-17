import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/exam_timetable_controller.dart';
import '../models/exam_paper.dart';
import 'add_exam_paper_sheet.dart';

/// Headmaster: build the subject-wise exam timetable for one category (term).
/// Pick a class, then add subjects each with a date and optional time.
class ExamTimetableView extends GetView<ExamTimetableController> {
  const ExamTimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Obx(() => Text('${controller.categoryName.value} Timetable')),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null && controller.classes.isEmpty) {
          return Center(
            child: Text(controller.error.value!, style: AppTypography.bodyLg),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackLg,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXxl,
          ),
          children: [
            Text(
              'Class',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            _ClassPicker(controller: controller),
            const SizedBox(height: AppSpacing.stackLg),
            if (controller.selectedClassId.value == null)
              _Hint(
                'Pick a class to build its exam schedule. Each class can have '
                'its own subject dates under $categoryHint.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${controller.selectedClassLabel} — Subjects',
                      style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addSubject(context),
                    icon: const Icon(AppIcons.addRounded, size: 18),
                    label: const Text('Add subject'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              if (controller.papersLoading.value)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.papers.isEmpty)
                _Hint('No subjects scheduled yet. Tap “Add subject”.')
              else
                for (final p in controller.papers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _PaperTile(paper: p, controller: controller),
                  ),
            ],
          ],
        );
      }),
    );
  }

  String get categoryHint => controller.categoryName.value;

  Future<void> _addSubject(BuildContext context) async {
    if (controller.subjects.isEmpty) {
      Get.snackbar(
        'No subjects',
        'Add subjects to the school first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await showAddExamPaperSheet(controller);
  }
}

class _ClassPicker extends StatelessWidget {
  final ExamTimetableController controller;
  const _ClassPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedClassId.value,
          isExpanded: true,
          hint: Text('Select a class', style: AppTypography.bodyLg),
          items: [
            for (final c in controller.classes)
              DropdownMenuItem(value: c.id, child: Text(c.label)),
          ],
          onChanged: controller.selectClass,
        ),
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  final ExamPaper paper;
  final ExamTimetableController controller;
  const _PaperTile({required this.paper, required this.controller});

  String get _schedule {
    final d = paper.examDate;
    if (d == null) return 'Date not set';
    final date =
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time = paper.examTime;
    return time == null || time.isEmpty ? date : '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackLg,
        vertical: AppSpacing.stackMd,
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.menuBookRounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.subjectName(paper.subjectId),
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _schedule,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${paper.maxMarks.toStringAsFixed(0)} max',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
