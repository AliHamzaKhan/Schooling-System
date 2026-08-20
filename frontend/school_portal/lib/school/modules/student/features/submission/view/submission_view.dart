import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../assignments/models/assignment.dart';
import '../components/dashed_upload_box.dart';
import '../controller/submission_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Assignment Detail / Submission — an enhanced header (subject, due, points),
/// instructions, then either the submit form (un-submitted) or the read-only
/// state: Your Submission (file + teacher comments), a Final Grade hero once
/// graded, and the Submission Status timeline.
class SubmissionView extends GetView<SubmissionController> {
  const SubmissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          PortalTopBar(
            title: 'Meri Taleem',
            onBell: () => Get.back<void>(),
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(AppIcons.arrowBackRounded, color: AppColors.primary),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const SkeletonPage(withHeader: false, body: SkeletonCardList(count: 3, height: 130));
              }
              final a = controller.assignment.value;
              if (a == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  _HeaderCard(assignment: a),
                  const SizedBox(height: AppSpacing.stackLg),
                  // Already turned in → read-only status. Otherwise the submit
                  // form. `showForm` also covers an opt-in "replace submission".
                  Obx(() => controller.showForm
                      ? _SubmitForm(controller: controller)
                      : _SubmittedState(
                          submission: controller.assignment.value!.submission!,
                          maxMarks: controller.assignment.value!.points,
                          onResubmit: controller.startResubmit,
                        )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Assignment header: subject pill + points on the right, title, due line,
/// then the instructions and any reference material.
class _HeaderCard extends StatelessWidget {
  final StudentAssignment assignment;
  const _HeaderCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: _SubjectPill(subject: a.subject, accent: a.accent)),
              const Spacer(),
              if (a.points > 0) _PointsBadge(points: a.points),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(a.title, style: AppTypography.displayLg.copyWith(fontSize: 28)),
          if (a.dueLine.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Icon(
                  a.dueIsUrgent
                      ? AppIcons.accessTimeRounded
                      : AppIcons.calendarTodayOutlined,
                  size: 15,
                  color: a.dueIsUrgent
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(a.dueLine,
                    style: AppTypography.bodyLg.copyWith(
                      color: a.dueIsUrgent
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                      fontWeight:
                          a.dueIsUrgent ? FontWeight.w700 : FontWeight.w400,
                    )),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Instructions',
              style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(a.description, style: AppTypography.bodyLg),
          if (a.attachment != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _ReferenceBox(filename: a.attachment!),
          ],
        ],
      ),
    );
  }
}

class _SubjectPill extends StatelessWidget {
  final String subject;
  final Color accent;
  const _SubjectPill({required this.subject, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.bookmarkRounded, size: 14, color: accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(subject.isEmpty ? 'Assignment' : subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd
                    .copyWith(color: accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// The submit form (file drop + notes + Turn In). Shown for un-submitted work,
/// or when the student opts to replace an existing (ungraded) submission.
class _SubmitForm extends StatefulWidget {
  final SubmissionController controller;
  const _SubmitForm({required this.controller});

  @override
  State<_SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends State<_SubmitForm> with ScreenTextControllers {
  SubmissionController get controller => widget.controller;

  // Owned by this form — created with it, disposed with it.
  late final _notesCtrl = boundController(controller.notes);

  @override
  Widget build(BuildContext context) {
    final resubmitting = controller.resubmit.value;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.cloudUploadOutlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(resubmitting ? 'Replace Submission' : 'Submit Assignment',
                  style: AppTypography.titleLg),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Obx(() => DashedUploadBox(
                filename: controller.filename.value,
                onTap: controller.pickFile,
              )),
          const SizedBox(height: AppSpacing.stackMd),
          PortalFormField(
            label: 'Additional Notes (Optional)',
            hint: 'Add any comments for your teacher here…',
            controller: _notesCtrl,
            maxLines: 3,
          ),
          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.stackMd),
              child: Text(err,
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error)),
            );
          }),
          const SizedBox(height: AppSpacing.stackLg),
          Obx(() => PrimaryButton(
                label: resubmitting ? 'Resubmit' : 'Turn In Assignment',
                leadingIcon: AppIcons.sendRounded,
                trailingIcon: null,
                expanded: true,
                isLoading: controller.submitting.value,
                onPressed: controller.submit,
              )),
          if (resubmitting) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Center(
              child: TextButton(
                onPressed: controller.cancelResubmit,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Read-only state for an already-submitted assignment: Your Submission
/// (file + teacher comments), the Final Grade hero once graded, and the
/// Submission Status timeline.
class _SubmittedState extends StatelessWidget {
  final StudentSubmission submission;
  final int maxMarks;
  final VoidCallback onResubmit;
  const _SubmittedState({
    required this.submission,
    required this.maxMarks,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _YourSubmissionCard(submission: submission),
        if (submission.isGraded) ...[
          const SizedBox(height: AppSpacing.stackLg),
          _FinalGradeCard(submission: submission, maxMarks: maxMarks),
        ],
        const SizedBox(height: AppSpacing.stackLg),
        _SubmissionTimelineCard(submission: submission),
        if (!submission.isGraded) ...[
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onResubmit,
              icon: const Icon(AppIcons.refreshRounded, size: 18),
              label: const Text('Replace submission'),
            ),
          ),
        ],
      ],
    );
  }
}

class _YourSubmissionCard extends StatelessWidget {
  final StudentSubmission submission;
  const _YourSubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final hasFeedback = (submission.feedback ?? '').isNotEmpty;
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your Submission', style: AppTypography.titleLg),
              const Spacer(),
              _StatusChip(submission: submission),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          if (submission.attachmentUrl != null)
            _SubmittedFileRow(
              url: submission.attachmentUrl!,
              submittedOn: submission.submittedOn,
            )
          else
            Text('No file attached to this submission.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          if (hasFeedback) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teacher Comments',
                      style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(submission.feedback!, style: AppTypography.bodyLg),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Navy hero showing the awarded letter grade + percentage once graded.
class _FinalGradeCard extends StatelessWidget {
  final StudentSubmission submission;
  final int maxMarks;
  const _FinalGradeCard({required this.submission, required this.maxMarks});

  @override
  Widget build(BuildContext context) {
    final marks = submission.marksObtained ?? 0;
    final pct = maxMarks > 0 ? (marks / maxMarks * 100).round() : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(color: Color(0x330F172A), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(AppIcons.starRounded,
                  size: 72, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('FINAL GRADE',
                  style: AppTypography.labelCaps.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(pct == null ? _fmt(marks) : _letter(pct.toDouble()),
                  style: AppTypography.displayLg
                      .copyWith(fontSize: 52, color: AppColors.onPrimary)),
              const SizedBox(height: 2),
              Text(
                maxMarks > 0
                    ? '${_fmt(marks)} / $maxMarks   ·   $pct%'
                    : _fmt(marks),
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static String _letter(double pct) {
    if (pct >= 95) return 'A+';
    if (pct >= 90) return 'A';
    if (pct >= 85) return 'A-';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'B-';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }
}

class _SubmissionTimelineCard extends StatelessWidget {
  final StudentSubmission submission;
  const _SubmissionTimelineCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.assignmentTurnedInOutlined,
                  size: 18, color: AppColors.tertiary),
              const SizedBox(width: 6),
              Text('Submission Status', style: AppTypography.titleLg),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _StatusStep(
            icon: AppIcons.sendRounded,
            title: submission.isLate ? 'Submitted (late)' : 'Submitted',
            subtitle: submission.submittedOn.isEmpty
                ? 'Turned in'
                : submission.submittedOn,
            done: true,
            accent:
                submission.isLate ? const Color(0xFFE8A317) : AppColors.tertiary,
          ),
          _StatusStep(
            icon: submission.isRejected
                ? AppIcons.reportGmailerrorredRounded
                : (submission.isSeen
                    ? AppIcons.markEmailReadOutlined
                    : AppIcons.reviewsOutlined),
            title: submission.isRejected
                ? 'Needs resubmission'
                : (submission.isReviewed
                    ? 'Reviewed'
                    : (submission.isSeen ? 'Read by teacher' : 'Under review')),
            subtitle: submission.isReviewed
                ? 'Your teacher has reviewed this'
                : (submission.isSeen
                    ? 'Your teacher has opened your submission'
                    : 'Waiting for your teacher'),
            done: submission.isSeen,
            accent: submission.isRejected ? AppColors.error : AppColors.primary,
          ),
          _StatusStep(
            icon: AppIcons.gradeOutlined,
            title: submission.isGraded ? 'Graded' : 'Grade pending',
            subtitle: submission.isGraded
                ? 'Score released'
                : 'Marks appear here once graded',
            done: submission.isGraded,
            accent: AppColors.tertiary,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final StudentSubmission submission;
  const _StatusChip({required this.submission});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    if (submission.isGraded) {
      label = 'Graded';
      color = AppColors.tertiary;
    } else if (submission.isRejected) {
      label = 'Rejected';
      color = AppColors.error;
    } else if (submission.status == 'approved') {
      label = 'Approved';
      color = AppColors.tertiary;
    } else {
      label = 'Sent';
      color = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.labelMd
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final Color accent;
  final bool isLast;
  const _StatusStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.accent,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dim = AppColors.onSurfaceVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: done
                      ? accent.withValues(alpha: 0.14)
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: done ? accent : dim),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.stackMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: done ? AppColors.onSurface : dim)),
                  Text(subtitle,
                      style: AppTypography.bodySm.copyWith(color: dim)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedFileRow extends StatelessWidget {
  final String url;
  final String submittedOn;
  const _SubmittedFileRow({required this.url, this.submittedOn = ''});

  @override
  Widget build(BuildContext context) {
    final name = url.split('/').last;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(AppIcons.pictureAsPdfRounded,
                size: 20, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                if (submittedOn.isNotEmpty)
                  Text('Submitted $submittedOn',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const Icon(AppIcons.downloadRounded,
              size: 20, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$points',
            style: AppTypography.displayLg
                .copyWith(fontSize: 24, color: AppColors.primary)),
        Text('Points Possible',
            style: AppTypography.labelMd
                .copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _ReferenceBox extends StatelessWidget {
  final String filename;
  const _ReferenceBox({required this.filename});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.attachFileRounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Reference Materials',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(AppIcons.insertDriveFileOutlined,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(filename, style: AppTypography.bodyMd)),
            ],
          ),
        ],
      ),
    );
  }
}
