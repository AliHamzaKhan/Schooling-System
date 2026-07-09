import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../config/teacher_routes.dart';
import '../controller/quizzes_controller.dart';
import '../models/quiz_models.dart';

/// Teacher Quizzes — list of created quizzes with status, and a FAB to author a
/// new one.
class QuizzesView extends GetView<QuizzesController> {
  const QuizzesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // No <bool> generic — Get.toNamed<T> throws a route cast error on
          // GetX 4.6.x; the dynamic result still compares fine.
          final created = await Get.toNamed(TeacherRoutes.createQuiz);
          if (created == true) controller.load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Create Quiz'),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        if (controller.quizzes.isEmpty) {
          return Center(
            child: Text('No quizzes yet — tap Create Quiz.',
                style: AppTypography.bodyLg),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              100),
          itemCount: controller.quizzes.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackMd),
          itemBuilder: (context, i) {
            final quiz = controller.quizzes[i];
            return _QuizRow(
              quiz: quiz,
              onTap: () => Get.toNamed(TeacherRoutes.quizPerformance,
                  arguments: quiz),
            );
          },
        );
      }),
    );
  }
}

class _QuizRow extends StatelessWidget {
  final TeacherQuiz quiz;
  final VoidCallback onTap;
  const _QuizRow({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (quiz.status) {
      'published' => ('Published', AppColors.tertiary),
      'closed' => ('Closed', AppColors.onSurfaceVariant),
      _ => ('Draft', const Color(0xFFE8A317)),
    };
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            const Icon(Icons.quiz_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Text(quiz.title,
                  style: AppTypography.titleMd
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(label,
                  style: AppTypography.labelMd.copyWith(color: color)),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
