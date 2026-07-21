import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../controller/quiz_performance_controller.dart';
import '../models/quiz_models.dart';
import '../../../../../widgets/skeletons.dart';

/// Quiz Performance — each student's score for one quiz (highest first).
class QuizPerformanceView extends GetView<QuizPerformanceController> {
  const QuizPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Obx(() => Text(controller.title.value))),
      body: Obx(() {
        if (controller.loading.value) {
          return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonRosterList()]));
        }
        if (controller.error.value != null) {
          return Center(
              child: Text(controller.error.value!, style: AppTypography.bodyLg));
        }
        final perf = controller.performance.value;
        if (perf == null || perf.rows.isEmpty) {
          return Center(
              child: Text('No students to report on yet.',
                  style: AppTypography.bodyLg));
        }
        final attempted = perf.rows.where((r) => r.submitted).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            Text(
              '$attempted of ${perf.rows.length} attempted · ${_fmt(perf.totalMarks)} marks total',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            for (final row in perf.rows) ...[
              _PerfRow(row: row, total: perf.totalMarks),
              const SizedBox(height: AppSpacing.stackSm),
            ],
          ],
        );
      }),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _PerfRow extends StatelessWidget {
  final QuizPerfRow row;
  final double total;
  const _PerfRow({required this.row, required this.total});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (row.status) {
      'graded' => ('Graded', AppColors.tertiary),
      'submitted' => ('Needs grading', const Color(0xFFE8A317)),
      'in_progress' => ('In progress', AppColors.primary),
      _ => ('Not attempted', AppColors.onSurfaceVariant),
    };
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Text(
              row.name.isEmpty ? '?' : row.name.characters.first.toUpperCase(),
              style: AppTypography.titleMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name.isEmpty ? 'Student' : row.name,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(label,
                    style: AppTypography.bodySm.copyWith(color: color)),
              ],
            ),
          ),
          Text(
            row.score == null ? '—' : '${_fmt(row.score!)}/${_fmt(total)}',
            style: AppTypography.titleLg.copyWith(
              fontWeight: FontWeight.w800,
              color: row.score == null ? AppColors.onSurfaceVariant : color,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
