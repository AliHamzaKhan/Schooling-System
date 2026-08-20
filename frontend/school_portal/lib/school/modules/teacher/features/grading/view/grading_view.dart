import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

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
      onTap: () => _showDetail(context),
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
            InkWell(
              onTap: () => _openAttachment(context),
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.pictureAsPdfRounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(row.attachmentUrl!.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.primary)),
                    ),
                    Text('View',
                        style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const Icon(AppIcons.openInNewRounded,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
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
              icon: Icon(row.isGraded ? AppIcons.editRounded : AppIcons.gradeRounded,
                  size: 18),
              label: Text(row.isGraded ? 'Update grade' : 'Grade'),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the attached PDF in the device's external viewer/browser. The file
  /// is served publicly under `/media`, so no auth is needed.
  Future<void> _openAttachment(BuildContext context) async {
    final raw = row.attachmentUrl ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.parse(EnvConfig.mediaUrl(raw));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the attachment.')),
      );
    }
  }

  /// Full submission detail: the student's written response and attachment,
  /// with quick actions to view the file and grade.
  void _showDetail(BuildContext context) {
    final hasContent = (row.content ?? '').isNotEmpty;
    final hasFile = (row.attachmentUrl ?? '').isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(row.studentName ?? 'Student',
                  style: AppTypography.titleLg
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Submitted ${row.submittedOn}',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.stackLg),
              Text('Response',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    hasContent ? row.content! : 'No written response.',
                    style: AppTypography.bodyMd.copyWith(
                        color: hasContent
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              if (hasFile)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      _openAttachment(context);
                    },
                    icon: const Icon(AppIcons.pictureAsPdfRounded, size: 18),
                    label: const Text('View attached PDF'),
                  ),
                )
              else
                Text('No file attached.',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.stackSm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    onGrade();
                  },
                  icon: Icon(
                      row.isGraded ? AppIcons.editRounded : AppIcons.gradeRounded,
                      size: 18),
                  label: Text(row.isGraded ? 'Update grade' : 'Grade'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
}
