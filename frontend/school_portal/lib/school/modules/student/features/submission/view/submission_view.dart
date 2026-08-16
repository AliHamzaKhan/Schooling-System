import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../assignments/models/assignment.dart';
import '../components/dashed_upload_box.dart';
import '../controller/submission_controller.dart';
import '../../../../../widgets/skeletons.dart';

/// Assignment Detail / Submission — subject pill, title, due line, points
/// badge, instructions, optional reference materials, then a "Submit
/// Assignment" card with a dashed file drop zone, an additional-notes field,
/// and a Turn In CTA.
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
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
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
                  GlassSurface(
                    padding: EdgeInsets.zero,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 5,
                            decoration: BoxDecoration(
                              color: a.accent,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(AppRadius.card),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.stackLg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bookmark_outline_rounded,
                                            size: 14, color: a.accent),
                                        const SizedBox(width: 4),
                                        Text(a.subject,
                                            style: AppTypography.labelMd
                                                .copyWith(color: AppColors.onSurface)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.stackMd),
                                  Text(a.title,
                                      style: AppTypography.displayLg
                                          .copyWith(fontSize: 30)),
                                  const SizedBox(height: AppSpacing.stackSm),
                                  Text(a.dueLine, style: AppTypography.bodyLg),
                                  const SizedBox(height: AppSpacing.stackMd),
                                  _PointsBadge(points: a.points),
                                  const SizedBox(height: AppSpacing.stackLg),
                                  Text('Instructions',
                                      style: AppTypography.titleMd
                                          .copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(a.description, style: AppTypography.bodyLg),
                                  if (a.attachment != null) ...[
                                    const SizedBox(height: AppSpacing.stackMd),
                                    _ReferenceBox(filename: a.attachment!),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  // Already turned in → read-only status. Otherwise the submit
                  // form. `showForm` also covers an opt-in "replace submission".
                  Obx(() => controller.showForm
                      ? _SubmitForm(controller: controller)
                      : _SubmissionStatus(
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
              const Icon(Icons.cloud_upload_outlined,
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
                leadingIcon: Icons.send_rounded,
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

/// Read-only status for an assignment the student has already turned in: a
/// progress timeline (Submitted → Under review → Graded), the attached file,
/// and the awarded marks + teacher feedback once graded.
class _SubmissionStatus extends StatelessWidget {
  final StudentSubmission submission;
  final int maxMarks;
  final VoidCallback onResubmit;
  const _SubmissionStatus({
    required this.submission,
    required this.maxMarks,
    required this.onResubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined,
                  size: 18, color: AppColors.tertiary),
              const SizedBox(width: 6),
              Text('Submission Status', style: AppTypography.titleLg),
              const Spacer(),
              _StatusChip(submission: submission),
            ],
          ),
          const SizedBox(height: AppSpacing.stackLg),

          // Progress timeline.
          _StatusStep(
            icon: Icons.send_rounded,
            title: submission.isLate ? 'Submitted (late)' : 'Submitted',
            subtitle: submission.submittedOn.isEmpty
                ? 'Turned in'
                : 'Turned in on ${submission.submittedOn}',
            done: true,
            accent:
                submission.isLate ? const Color(0xFFE8A317) : AppColors.tertiary,
          ),
          _StatusStep(
            icon: submission.isRejected
                ? Icons.report_gmailerrorred_rounded
                : (submission.isSeen
                    ? Icons.mark_email_read_outlined
                    : Icons.reviews_outlined),
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
            accent:
                submission.isRejected ? AppColors.error : AppColors.primary,
          ),
          _StatusStep(
            icon: Icons.grade_outlined,
            title: submission.isGraded ? 'Graded' : 'Grade pending',
            subtitle: submission.isGraded
                ? 'Score released'
                : 'Marks appear here once graded',
            done: submission.isGraded,
            accent: AppColors.tertiary,
            isLast: true,
          ),

          if (submission.attachmentUrl != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _SubmittedFileRow(url: submission.attachmentUrl!),
          ],

          // Marks + feedback (graded only).
          if (submission.isGraded) ...[
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Marks',
                      style: AppTypography.labelCaps
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                    maxMarks > 0
                        ? '${_fmt(submission.marksObtained)} / $maxMarks'
                        : _fmt(submission.marksObtained),
                    style: AppTypography.displayLg.copyWith(
                        fontSize: 26, color: AppColors.tertiary),
                  ),
                  if ((submission.feedback ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.stackSm),
                    Text('Teacher feedback',
                        style: AppTypography.labelMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(submission.feedback!, style: AppTypography.bodyMd),
                  ],
                ],
              ),
            ),
          ],

          // Replace submission — only while it can still be changed.
          if (!submission.isGraded) ...[
            const SizedBox(height: AppSpacing.stackLg),
            OutlinedButton.icon(
              onPressed: onResubmit,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Replace submission'),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
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
                child: Icon(icon,
                    size: 17, color: done ? accent : dim),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.outlineVariant,
                  ),
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
  const _SubmittedFileRow({required this.url});

  @override
  Widget build(BuildContext context) {
    final name = url.split('/').last;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$points',
              style: AppTypography.displayLg
                  .copyWith(fontSize: 22, color: AppColors.onPrimary)),
          Text('POINTS',
              style: AppTypography.labelCaps
                  .copyWith(color: AppColors.onPrimary, letterSpacing: 1)),
        ],
      ),
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
              const Icon(Icons.attach_file_rounded,
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
              const Icon(Icons.insert_drive_file_outlined,
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
