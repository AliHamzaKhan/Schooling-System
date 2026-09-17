import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/promotion_controller.dart';
import '../models/promotion_models.dart';

/// Headmaster: promote students from a published exam. Passed students default
/// to Promote (pick their next class+section); failed students can be Bypassed
/// (promoted anyway) or flagged for Re-exam.
class PromotionView extends GetView<PromotionController> {
  const PromotionView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Student Promotion')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 96));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackLg,
                  AppSpacing.containerPaddingMobile,
                  0),
              child: _ExamPicker(controller: controller),
            ),
            Expanded(child: _PreviewList(controller: controller)),
            _ApplyBar(controller: controller),
          ],
        );
      }),
    );
  }
}

class _ExamPicker extends StatelessWidget {
  final PromotionController controller;
  const _ExamPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EXAM',
            style: AppTypography.labelCaps
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Obx(
            () => DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: controller.selectedExamId.value,
                hint: const Text('Choose a published exam'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Choose a published exam')),
                  for (final e in controller.exams)
                    DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
                onChanged: controller.selectExam,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewList extends StatelessWidget {
  final PromotionController controller;
  const _PreviewList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedExamId.value == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXl),
            child: Text('Pick an exam to see promotion suggestions.',
                textAlign: TextAlign.center, style: AppTypography.bodyLg),
          ),
        );
      }
      if (controller.previewLoading.value) {
        return const SkeletonPage(body: SkeletonCardList(count: 4, height: 120));
      }
      if (controller.previewError.value != null) {
        return Center(
            child: Text(controller.previewError.value!,
                style: AppTypography.bodyLg));
      }
      if (controller.rows.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackXl),
            child: Text(
                'No results for this exam yet.\nPublish its results first.',
                textAlign: TextAlign.center, style: AppTypography.bodyLg),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd),
        itemCount: controller.rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackMd),
        itemBuilder: (_, i) =>
            _PromotionRowCard(controller: controller, row: controller.rows[i]),
      );
    });
  }
}

class _PromotionRowCard extends StatelessWidget {
  final PromotionController controller;
  final PromotionPreviewRow row;
  const _PromotionRowCard({required this.controller, required this.row});

  @override
  Widget build(BuildContext context) {
    final passColor = row.passed ? AppColors.tertiary : AppColors.error;
    final pct = row.percentage == null
        ? '—'
        : '${row.percentage!.toStringAsFixed(1)}%';
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.studentName ?? 'Student',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: passColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('${row.passed ? 'Pass' : 'Fail'} · $pct',
                    style: AppTypography.labelMd.copyWith(
                        color: passColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (row.currentSectionLabel != null) ...[
            const SizedBox(height: 2),
            Text('Current: ${row.currentSectionLabel}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() {
            final outcome = controller.outcomes[row.studentId] ??
                PromotionOutcome.retained;
            // Passed students: Promote or Retain. Failed students additionally
            // get Re-exam (and Promote acts as the headmaster "bypass").
            final options = <PromotionOutcome>[
              PromotionOutcome.promoted,
              PromotionOutcome.retained,
              if (!row.passed) PromotionOutcome.reexam,
            ];
            return Wrap(
              spacing: AppSpacing.stackSm,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o == PromotionOutcome.promoted && !row.passed
                        ? 'Bypass'
                        : o.label),
                    selected: outcome == o,
                    onSelected: (_) =>
                        controller.setOutcome(row.studentId, o),
                  ),
              ],
            );
          }),
          Obx(() {
            final outcome = controller.outcomes[row.studentId];
            if (outcome != PromotionOutcome.promoted) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackMd),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: controller.targets[row.studentId],
                    hint: const Text('Promote to class & section'),
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('Promote to class & section')),
                      for (final s in controller.sections)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => controller.setTarget(row.studentId, v),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ApplyBar extends StatelessWidget {
  final PromotionController controller;
  const _ApplyBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.rows.isEmpty) return const SizedBox.shrink();
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: PrimaryButton(
            label: 'Apply Promotions (${controller.rows.length})',
            expanded: true,
            isLoading: controller.applying.value,
            onPressed: controller.applying.value ? null : controller.apply,
          ),
        ),
      );
    });
  }
}
