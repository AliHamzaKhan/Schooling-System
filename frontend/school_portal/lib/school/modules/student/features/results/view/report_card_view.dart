import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/student_repository.dart';
import '../models/exam_result.dart';
import '../models/report_card.dart';
import '../../../../../widgets/skeletons.dart';

/// Per-subject report card for one exam, reached by tapping an exam on the
/// Results screen. The [ExamResultItem] is passed via [Get.arguments] for the
/// header; the per-subject lines are fetched live.
class ReportCardView extends StatefulWidget {
  const ReportCardView({super.key});

  @override
  State<ReportCardView> createState() => _ReportCardViewState();
}

class _ReportCardViewState extends State<ReportCardView> {
  ExamResultItem? _exam;
  bool _loading = true;
  String? _error;
  ReportCard? _card;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _exam = arg is ExamResultItem ? arg : null;
    _load();
  }

  Future<void> _load() async {
    final examId = _exam?.examId ?? '';
    if (examId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No exam selected.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await Get.find<StudentRepository>().loadReportCard(examId);
    if (!mounted) return;
    setState(() {
      if (res.success) {
        _card = res.data;
      } else {
        _error = res.error ?? 'Could not load the report card.';
      }
      _loading = false;
    });
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(_exam?.examName ?? 'Report Card')),
      body: Builder(builder: (context) {
        if (_loading) {
          return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3, height: 120)]));
        }
        if (_error != null) {
          return Center(
              child: Text(_error!, style: AppTypography.bodyLg));
        }
        final card = _card;
        if (card == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackXl),
          children: [
            // Overall summary.
            Container(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${card.percentage.toStringAsFixed(0)}%',
                          style: AppTypography.displayLg.copyWith(
                              fontSize: 44, color: AppColors.onPrimary)),
                      Text('${_fmt(card.totalMarks)} / ${_fmt(card.maxTotal)}',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onPrimary)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(card.grade.isEmpty ? '—' : card.grade,
                          style: AppTypography.displayLg.copyWith(
                              fontSize: 40, color: AppColors.onPrimary)),
                      Text(card.passed ? 'Pass' : 'Fail',
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Subjects', style: AppTypography.titleLg),
            const SizedBox(height: AppSpacing.stackMd),
            if (card.lines.isEmpty)
              GlassSurface(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Text('No subject marks recorded for this exam.',
                    style: AppTypography.bodyMd),
              )
            else
              for (final line in card.lines) ...[
                _SubjectRow(line: line),
                const SizedBox(height: AppSpacing.stackSm),
              ],
            if (!card.published) ...[
              const SizedBox(height: AppSpacing.stackMd),
              Text('These results are provisional (not yet published).',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ],
        );
      }),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final ReportCardLine line;
  const _SubjectRow({required this.line});

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final color = line.isAbsent
        ? AppColors.onSurfaceVariant
        : (line.passed ? AppColors.tertiary : AppColors.error);
    final scoreText = line.isAbsent
        ? 'Absent'
        : '${_fmt(line.marksObtained ?? 0)} / ${_fmt(line.maxMarks)}';
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Expanded(
            child: Text(line.subject,
                style: AppTypography.titleMd
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(scoreText,
              style: AppTypography.titleMd
                  .copyWith(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
