import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/section_header.dart';
import '../../../../../widgets/status_pill.dart';
import '../../../shared/widgets/child_switcher.dart';
import '../controller/report_card_controller.dart';
import '../models/report_card_data.dart';
import '../../../../../widgets/skeletons.dart';

/// Report Card — drill-in screen showing the active child's term results
/// (per-subject letter grade + percent), the term GPA, and a GPA trend chart.
class ReportCardView extends GetView<ReportCardController> {
  const ReportCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          const PortalTopBar(title: 'Report Card', showAvatar: false),
          const ChildSwitcher(),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(body: Column(children: [SkeletonStatGrid(count: 2), SizedBox(height: AppSpacing.stackLg), SkeletonCardList(count: 3, height: 120)]));
              }
              final d = controller.data.value;
              if (d == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackSm,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  PrimaryButton(
                    label: 'Download PDF Report',
                    leadingIcon: AppIcons.downloadRounded,
                    trailingIcon: null,
                    expanded: true,
                    onPressed: () => Get.snackbar(
                      'Report Card',
                      'Your PDF report will download shortly.',
                      snackPosition: SnackPosition.BOTTOM,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Row(
                    children: [
                      Expanded(
                        child: SectionHeader(title: d.termLabel),
                      ),
                      StatusPill(
                        label: 'GPA: ${d.gpa.toStringAsFixed(1)}',
                        color: AppColors.primary,
                        icon: AppIcons.schoolRounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.subjects.isEmpty)
                    const _Empty(text: 'No results published yet.')
                  else
                    for (final s in d.subjects) ...[
                      _SubjectCard(subject: s),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'GPA Trend'),
                  const SizedBox(height: 6.0),
                  Text('Consistent performance across terms.',
                      style: AppTypography.bodyMd),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (d.gpaTrend.isNotEmpty) _GpaTrendChart(points: d.gpaTrend),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Colour accent for a letter grade band (A → green, B → amber, else navy).
Color _accentFor(String grade) {
  final g = grade.isEmpty ? '' : grade[0].toUpperCase();
  switch (g) {
    case 'A':
      return AppColors.tertiary;
    case 'B':
      return const Color(0xFFE8A317);
    case 'C':
      return AppColors.primary;
    default:
      return AppColors.error;
  }
}

class _SubjectCard extends StatelessWidget {
  final ReportSubject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(subject.grade);
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.subject,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if (subject.course != null)
                  Text(subject.course!, style: AppTypography.bodyMd),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(subject.grade,
                  style: AppTypography.headlineLg
                      .copyWith(color: accent, fontSize: 26)),
              Text('${subject.percent}%', style: AppTypography.labelMd),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpaTrendChart extends StatelessWidget {
  final List<GpaTrendPoint> points;
  const _GpaTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    const maxGpa = 4.0;
    return GlassSurface(
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final p in points)
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(p.gpa.toStringAsFixed(1),
                          style: AppTypography.labelMd),
                      const SizedBox(height: 4),
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: (p.gpa / maxGpa).clamp(0.05, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.button)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(p.label, style: AppTypography.labelMd),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      child: Row(
        children: [
          const Icon(AppIcons.inboxOutlined, color: AppColors.outline),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(child: Text(text, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}
