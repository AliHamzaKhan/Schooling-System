import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../components/section_card.dart';
import '../controller/create_exam_controller.dart';

/// Create New Exam — sectioned form (Basic Information, Exam Content,
/// Logistics, Grading) with a Save & Create primary action and a Save as Draft
/// outlined secondary action.
class CreateExamView extends GetView<CreateExamController> {
  const CreateExamView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackSm, AppSpacing.stackMd, AppSpacing.containerPaddingMobile, 0),
            child: GestureDetector(
              onTap: () => Get.back<void>(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Back to Exam Center',
                      style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPaddingMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Exam',
                    style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Design a comprehensive assessment for your students.',
                    style: AppTypography.bodyLg),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                _BasicInfo(controller: controller),
                const SizedBox(height: AppSpacing.stackLg),
                _ExamContent(controller: controller),
                const SizedBox(height: AppSpacing.stackLg),
                _Logistics(controller: controller),
                const SizedBox(height: AppSpacing.stackLg),
                _Grading(controller: controller),
                const SizedBox(height: AppSpacing.stackLg),
                Obx(() {
                  final err = controller.error.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                    child: Text(err,
                        style: AppTypography.bodySm.copyWith(color: AppColors.error)),
                  );
                }),
                Obx(() => PrimaryButton(
                      label: 'Save & Create Exam',
                      leadingIcon: Icons.save_outlined,
                      trailingIcon: null,
                      expanded: true,
                      isLoading: controller.submitting.value,
                      onPressed: () => controller.save(asDraft: false),
                    )),
                const SizedBox(height: AppSpacing.stackSm),
                Obx(() => GhostButton(
                      label: 'Save as Draft',
                      expanded: true,
                      onPressed: controller.savingDraft.value
                          ? null
                          : () => controller.save(asDraft: true),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfo extends StatelessWidget {
  final CreateExamController controller;
  const _BasicInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Basic Information',
      children: [
        PortalFormField(
          label: 'Exam Title',
          hint: 'e.g., Midterm Calculus Assessme',
          controller: controller.titleCtrl,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(() => PortalDropdownField<String>(
                    label: 'Subject',
                    hint: 'Select a subject',
                    value: controller.selectedSubject.value,
                    items: CreateExamController.subjects,
                    labelOf: (s) => s,
                    onChanged: controller.selectSubject,
                  )),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Obx(() => PortalDropdownField<String>(
              label: 'Grade Level / Class',
              hint: 'Select class',
              value: controller.selectedClass.value,
              items: CreateExamController.classes,
              labelOf: (s) => s,
              onChanged: controller.selectClass,
            )),
        const SizedBox(height: AppSpacing.stackMd),
        PortalFormField(
          label: 'Instructions for Students',
          hint: 'Enter any specific instructions…',
          controller: controller.instructionsCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _ExamContent extends StatelessWidget {
  final CreateExamController controller;
  const _ExamContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.menu_book_outlined,
      accent: const Color(0xFFE8A317),
      title: 'Exam\nContent',
      trailing: Obx(() => Text('${controller.questionsAdded.value} Questions Added',
          style: AppTypography.bodyMd)),
      children: [
        DashedDropZone(
          icon: Icons.add,
          title: 'Add Questions Manually',
          subtitle: 'Build multiple choice, essay, or true/false questions.',
          actionLabel: 'Open Builder',
          onAction: () => controller.questionsAdded.value++,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        DashedDropZone(
          icon: Icons.upload_file_outlined,
          title: 'Upload PDF',
          subtitle: "Upload an existing paper. We'll digitize it for grading.",
          actionLabel: 'Select File',
        ),
      ],
    );
  }
}

class _Logistics extends StatelessWidget {
  final CreateExamController controller;
  const _Logistics({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.schedule_rounded,
      accent: AppColors.tertiary,
      title: 'Logistics',
      children: [
        PortalFormField(
          label: 'Date',
          hint: 'mm/dd/yyyy',
          controller: controller.dateCtrl,
          suffix: const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PortalFormField(
                label: 'Start Time',
                hint: '--:-- --',
                controller: controller.startCtrl,
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: PortalFormField(
                label: 'End Time',
                hint: '--:-- --',
                controller: controller.endCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PortalFormField(
          label: 'Duration (Minutes)',
          hint: 'e.g., 90',
          controller: controller.durationCtrl,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

class _Grading extends StatelessWidget {
  final CreateExamController controller;
  const _Grading({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.grade_outlined,
      accent: AppColors.aiAccent,
      title: 'Grading',
      children: [
        PortalFormField(
          label: 'Total Marks Possible',
          hint: '100',
          controller: controller.totalMarksCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-grading',
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text('For multiple choice', style: AppTypography.bodySm),
                  ],
                ),
              ),
              Obx(() => Switch(
                    value: controller.autoGrading.value,
                    onChanged: controller.toggleAutoGrading,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
