import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
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
            title: 'EduMaster',
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
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('Submit Assignment',
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
                          controller: controller.notesCtrl,
                          maxLines: 3,
                        ),
                        Obx(() {
                          final err = controller.error.value;
                          if (err == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(
                                top: AppSpacing.stackMd),
                            child: Text(err,
                                style: AppTypography.bodyMd
                                    .copyWith(color: AppColors.error)),
                          );
                        }),
                        const SizedBox(height: AppSpacing.stackLg),
                        Obx(() => PrimaryButton(
                              label: 'Turn In Assignment',
                              leadingIcon: Icons.send_rounded,
                              trailingIcon: null,
                              expanded: true,
                              isLoading: controller.submitting.value,
                              onPressed: controller.submit,
                            )),
                      ],
                    ),
                  ),
                ],
              );
            }),
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
