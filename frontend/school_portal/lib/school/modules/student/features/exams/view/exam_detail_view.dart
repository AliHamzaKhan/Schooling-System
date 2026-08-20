import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/student_repository.dart';
import '../models/exam.dart';
import '../../../../../widgets/skeletons.dart';

/// Exam detail reached from the countdown / timeline cards. Shows the exam's
/// identity plus the papers (subjects) the teacher/headmaster scheduled, each
/// with its date and max/pass marks. The [UpcomingExam] is passed via
/// [Get.arguments]; the papers are fetched live by exam id.
class ExamDetailView extends StatefulWidget {
  const ExamDetailView({super.key});

  @override
  State<ExamDetailView> createState() => _ExamDetailViewState();
}

class _ExamDetailViewState extends State<ExamDetailView> {
  late final UpcomingExam _exam;
  bool _loading = true;
  String? _error;
  List<ExamPaper> _papers = const [];

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _exam = arg is UpcomingExam
        ? arg
        : const UpcomingExam(
            id: '', title: 'Exam', date: '', time: '', location: '',
            dateShort: '', accent: AppColors.primary);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await Get.find<StudentRepository>().loadExamPapers(_exam.id);
    if (!mounted) return;
    setState(() {
      if (res.success) {
        _papers = res.data ?? const [];
      } else {
        _error = res.error ?? 'Could not load exam details.';
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Exam Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackMd,
            AppSpacing.containerPaddingMobile,
            AppSpacing.stackXl),
        children: [
          // Identity card.
          GlassSurface(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_exam.title,
                    style: AppTypography.displayLg.copyWith(fontSize: 26)),
                const SizedBox(height: AppSpacing.stackSm),
                if (_exam.date.isNotEmpty)
                  _MetaRow(
                    icon: AppIcons.calendarTodayOutlined,
                    label: [_exam.date, _exam.time]
                        .where((s) => s.isNotEmpty)
                        .join('  •  '),
                  ),
                if (_exam.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _MetaRow(
                      icon: AppIcons.meetingRoomOutlined,
                      label: _exam.location),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text('Papers', style: AppTypography.titleLg),
          const SizedBox(height: AppSpacing.stackMd),
          if (_loading)
            const Shimmer(child: SkeletonCardList(count: 3, height: 72))
          else if (_error != null)
            Text(_error!, style: AppTypography.bodyLg)
          else if (_papers.isEmpty)
            GlassSurface(
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              child: Text(
                "The subjects for this exam haven't been scheduled yet.",
                style: AppTypography.bodyMd,
              ),
            )
          else
            for (final p in _papers) ...[
              _PaperTile(paper: p),
              const SizedBox(height: AppSpacing.stackMd),
            ],
        ],
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  final ExamPaper paper;
  const _PaperTile({required this.paper});

  @override
  Widget build(BuildContext context) {
    String marks(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Icon(AppIcons.menuBookOutlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paper.subject,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (paper.date.isNotEmpty) paper.date,
                    'Max ${marks(paper.maxMarks)} · Pass ${marks(paper.passMarks)}',
                  ].join('  •  '),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }
}
