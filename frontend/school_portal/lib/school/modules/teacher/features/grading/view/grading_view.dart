import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/skeletons.dart';
import '../controller/grading_controller.dart';
import '../models/submission_row.dart';

/// Teacher: submissions for one assignment, with a grade action per student.
class GradingView extends GetView<GradingController> {
  const GradingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 4, height: 120));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final subs = controller.submissions;
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
              Text(controller.assignment.title, style: AppTypography.headlineLg),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                subs.isEmpty
                    ? 'No submissions yet'
                    : '${subs.length} submitted · ${controller.gradedCount} graded'
                        '${controller.assignment.maxMarks != null ? ' · max ${_fmt(controller.assignment.maxMarks!)}' : ''}',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              if (subs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackXl),
                  child: Center(
                      child: Text('No students have turned this in yet.',
                          style: AppTypography.bodyLg)),
                )
              else
                for (final s in subs) ...[
                  _SubmissionCard(
                    row: s,
                    maxMarks: controller.assignment.maxMarks,
                    onGrade: () => controller.gradeFlow(s),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
            ],
          ),
        );
      }),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _SubmissionCard extends StatelessWidget {
  final SubmissionRow row;
  final double? maxMarks;
  final VoidCallback onGrade;
  const _SubmissionCard(
      {required this.row, required this.maxMarks, required this.onGrade});

  @override
  Widget build(BuildContext context) {
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
              if (row.isGraded)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    maxMarks != null
                        ? '${_fmt(row.marksObtained)} / ${_fmt(maxMarks!)}'
                        : _fmt(row.marksObtained),
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w700),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A317).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(row.isLate ? 'Late' : 'To grade',
                      style: AppTypography.labelMd.copyWith(
                          color: const Color(0xFFB0790F),
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Submitted ${row.submittedOn}',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
          if ((row.content ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text(row.content!, style: AppTypography.bodyMd),
          ],
          if ((row.attachmentUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(row.attachmentUrl!.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ],
          if (row.isGraded && (row.feedback ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Text('Feedback: ${row.feedback!}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onGrade,
              icon: Icon(row.isGraded ? Icons.edit_rounded : Icons.grade_rounded,
                  size: 18),
              label: Text(row.isGraded ? 'Update grade' : 'Grade'),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
}
