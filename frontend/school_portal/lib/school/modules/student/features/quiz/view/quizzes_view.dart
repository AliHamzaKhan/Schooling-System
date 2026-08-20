import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/student_routes.dart';
import '../controller/quizzes_controller.dart';
import '../models/quiz_models.dart';
import '../../../../../widgets/skeletons.dart';

/// Student Quizzes — published quizzes to play, showing the score for any the
/// student has already attempted.
class QuizzesView extends GetView<StudentQuizzesController> {
  const QuizzesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: SkeletonCardList(count: 5, height: 110));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.quizzes.isEmpty) {
          return Center(
              child: Text('No quizzes available yet.',
                  style: AppTypography.bodyLg));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          itemCount: controller.quizzes.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackMd),
          itemBuilder: (context, i) {
            final quiz = controller.quizzes[i];
            return _QuizRow(
              quiz: quiz,
              onPlay: () async {
                // NB: no <bool> generic — Get.toNamed<T> casts the route to
                // Route<T?> and throws on GetX 4.6.x. The dynamic result still
                // compares fine.
                final done =
                    await Get.toNamed(StudentRoutes.takeQuiz, arguments: quiz);
                if (done == true) controller.load();
              },
            );
          },
        );
      }),
    );
  }
}

class _QuizRow extends StatelessWidget {
  final StudentQuiz quiz;
  final VoidCallback onPlay;
  const _QuizRow({required this.quiz, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final attempted = quiz.isAttempted;
    final score = quiz.attempt?.score;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Icon(AppIcons.quizOutlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  attempted
                      ? 'Your score: ${_fmt(score ?? 0)}'
                      : 'Not attempted yet',
                  style: AppTypography.bodySm.copyWith(
                    color: attempted
                        ? AppColors.tertiary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (attempted)
            const Icon(AppIcons.checkCircleRounded, color: AppColors.tertiary)
          else
            _PlayButton(onTap: onPlay),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.playArrowRounded,
                  size: 18, color: AppColors.onPrimary),
              const SizedBox(width: 4),
              Text('Play',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
