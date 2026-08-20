import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/take_quiz_controller.dart';
import '../models/quiz_models.dart';
import '../../../../../widgets/skeletons.dart';

/// Take Quiz — renders questions to answer, then a result card with the
/// auto-graded score once submitted.
class TakeQuizView extends GetView<TakeQuizController> {
  const TakeQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(controller.title)),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(withHeader: false, body: SkeletonCardList(count: 4, height: 150));
        }
        if (controller.result.value != null) {
          return _ResultBody(
            result: controller.result.value!,
            total: controller.quiz.value?.totalMarks ?? 0,
          );
        }
        final quiz = controller.quiz.value;
        if (quiz == null) {
          return Center(
              child: Text(controller.error.value ?? 'Quiz unavailable.',
                  style: AppTypography.bodyLg));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              120),
          children: [
            Text(
              '${quiz.questions.length} questions · ${_fmt(quiz.totalMarks)} marks',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            for (var i = 0; i < quiz.questions.length; i++) ...[
              _QuestionCard(index: i, question: quiz.questions[i]),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            Obx(() {
              final err = controller.error.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                child: Text(err,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.error)),
              );
            }),
            Obx(() => PrimaryButton(
                  label:
                      'Submit (${controller.answeredCount}/${quiz.questions.length})',
                  leadingIcon: AppIcons.checkRounded,
                  trailingIcon: null,
                  expanded: true,
                  isLoading: controller.submitting.value,
                  onPressed: controller.submit,
                )),
          ],
        );
      }),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuizQuestionView question;
  const _QuestionCard({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TakeQuizController>();
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${question.prompt}',
              style:
                  AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.stackSm),
          for (final option in question.options)
            Obx(() {
              final selected = controller.answers[question.id] == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  onTap: () => controller.select(question.id, option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? AppIcons.radioButtonChecked
                              : AppIcons.radioButtonUnchecked,
                          size: 18,
                          color: selected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                            child: Text(option, style: AppTypography.bodyLg)),
                      ],
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

class _ResultBody extends StatelessWidget {
  final QuizResult result;
  final double total;
  const _ResultBody({required this.result, required this.total});

  @override
  Widget build(BuildContext context) {
    final pending = result.status == 'submitted'; // has short answers to grade
    final passed = total > 0 && result.score >= total / 2;
    final accent = pending
        ? AppColors.primary
        : (passed ? AppColors.tertiary : AppColors.error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pending
                  ? AppIcons.hourglassBottomRounded
                  : (passed
                      ? AppIcons.emojiEventsRounded
                      : AppIcons.replayRounded),
              size: 56,
              color: accent,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              '${_fmt(result.score)} / ${_fmt(total)}',
              style: AppTypography.displayLg.copyWith(fontSize: 40, color: accent),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              pending
                  ? 'Submitted — some answers need your teacher to grade.'
                  : (passed ? 'Great job — you passed! 🎉' : 'Keep practising!'),
              style: AppTypography.bodyLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackXl),
            PrimaryButton(
              label: 'Done',
              trailingIcon: null,
              expanded: true,
              onPressed: () => Get.back<bool>(result: true),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
