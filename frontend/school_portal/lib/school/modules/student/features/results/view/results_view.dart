import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../../quiz/models/quiz_models.dart';
import '../controller/results_controller.dart';
import '../models/exam_result.dart';
import '../../../../../widgets/skeletons.dart';

/// Student academic results — published exam grades + attempted quiz scores.
class ResultsView extends GetView<ResultsController> {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('My Results')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 5, height: 92));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final exams = controller.exams;
        final quizzes = controller.quizzes;
        if (exams.isEmpty && quizzes.isEmpty) {
          return Center(
              child: Text('No results published yet.',
                  style: AppTypography.bodyLg));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            if (exams.isNotEmpty) ...[
              _SummaryCard(average: controller.examAverage, exams: exams.length),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Exam Results', style: AppTypography.titleLg),
              const SizedBox(height: AppSpacing.stackMd),
              for (final e in exams) ...[
                _ExamRow(
                  result: e,
                  onTap: () => Get.toNamed(StudentRoutes.reportCard,
                      arguments: e),
                ),
                const SizedBox(height: AppSpacing.stackSm),
              ],
              const SizedBox(height: AppSpacing.stackMd),
            ],
            Text('Quiz Results', style: AppTypography.titleLg),
            const SizedBox(height: AppSpacing.stackMd),
            if (quizzes.isEmpty)
              GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Text("You haven't attempted any quizzes yet.",
                    style: AppTypography.bodyMd),
              )
            else
              for (final q in quizzes) ...[
                _QuizRow(quiz: q),
                const SizedBox(height: AppSpacing.stackSm),
              ],
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int average;
  final int exams;
  const _SummaryCard({required this.average, required this.exams});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$average%',
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 44, color: AppColors.onPrimary)),
              Text('Exam average',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$exams',
                  style: AppTypography.titleLg.copyWith(
                      color: AppColors.onPrimary, fontWeight: FontWeight.w800)),
              Text(exams == 1 ? 'exam' : 'exams',
                  style: AppTypography.bodySm.copyWith(color: AppColors.onPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final ExamResultItem result;
  final VoidCallback? onTap;
  const _ExamRow({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? AppColors.tertiary : AppColors.error;
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.examName,
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${_fmt(result.totalMarks)} / ${_fmt(result.maxTotal)}',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${result.percentage.toStringAsFixed(0)}%',
                    style: AppTypography.titleLg
                        .copyWith(fontWeight: FontWeight.w800, color: color)),
                _Pill(
                  label: result.grade.isEmpty
                      ? (result.passed ? 'Pass' : 'Fail')
                      : 'Grade ${result.grade}',
                  color: color,
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(AppIcons.chevronRightRounded,
                color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _QuizRow extends StatelessWidget {
  final StudentQuiz quiz;
  const _QuizRow({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final attempt = quiz.attempt;
    final graded = attempt?.status == 'graded';
    final (statusLabel, color) = graded
        ? ('Graded', AppColors.tertiary)
        : ('Submitted', const Color(0xFFE8A317));
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          const Icon(AppIcons.quizOutlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                _Pill(label: statusLabel, color: color),
              ],
            ),
          ),
          Text(
            attempt?.score == null ? '—' : _fmt(attempt!.score!),
            style: AppTypography.titleLg.copyWith(
              fontWeight: FontWeight.w800,
              color: graded ? AppColors.tertiary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.labelMd.copyWith(color: color)),
    );
  }
}
