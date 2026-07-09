import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../components/section_card.dart';
import '../controller/create_exam_controller.dart';
import '../models/exam_question.dart';

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
        Obx(() {
          final items = controller.subjects.toList();
          return PortalDropdownField<String>(
            label: 'Subject',
            hint: controller.loadingOptions.value
                ? 'Loading your subjects…'
                : (items.isEmpty ? 'No subjects assigned' : 'Select a subject'),
            value: controller.selectedSubject.value,
            items: items,
            labelOf: (s) => s,
            onChanged: controller.selectSubject,
          );
        }),
        const SizedBox(height: AppSpacing.stackMd),
        Obx(() {
          final items = controller.classes.toList();
          return PortalDropdownField<String>(
            label: 'Grade Level / Class',
            hint: controller.loadingOptions.value
                ? 'Loading your classes…'
                : (items.isEmpty ? 'No classes assigned' : 'Select class'),
            value: controller.selectedClass.value,
            items: items,
            labelOf: (s) => s,
            onChanged: controller.selectClass,
          );
        }),
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
      trailing: Obx(() => Text('${controller.questions.length} Questions Added',
          style: AppTypography.bodyMd)),
      children: [
        DashedDropZone(
          icon: Icons.add,
          title: 'Add Questions Manually',
          subtitle: 'Build multiple choice, essay, or true/false questions.',
          actionLabel: 'Open Builder',
          onAction: () => _openQuestionBuilder(context, controller),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Obx(() {
          final name = controller.pdfName.value;
          return DashedDropZone(
            icon: name == null
                ? Icons.upload_file_outlined
                : Icons.picture_as_pdf_outlined,
            title: name == null ? 'Upload PDF' : 'PDF Attached',
            subtitle: name ??
                "Upload an existing paper. We'll digitize it for grading.",
            actionLabel: name == null ? 'Select File' : 'Replace File',
            onAction: controller.pickPdf,
          );
        }),
        Obx(() {
          if (controller.questions.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: AppSpacing.stackMd),
              for (var i = 0; i < controller.questions.length; i++)
                _AddedQuestionRow(
                  index: i,
                  question: controller.questions[i],
                  onRemove: () => controller.removeQuestion(i),
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// A saved question row shown under the drop zones, with a delete affordance.
class _AddedQuestionRow extends StatelessWidget {
  final int index;
  final ExamQuestion question;
  final VoidCallback onRemove;
  const _AddedQuestionRow({
    required this.index,
    required this.question,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.stackMd, vertical: AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}.',
              style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.prompt,
                    style: AppTypography.bodyLg
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(question.type.label,
                    style: AppTypography.labelCaps
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
          readOnly: true,
          onTap: () => controller.pickDate(context),
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
                readOnly: true,
                onTap: () => controller.pickStartTime(context),
                suffix: const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: PortalFormField(
                label: 'End Time',
                hint: '--:-- --',
                controller: controller.endCtrl,
                readOnly: true,
                onTap: () => controller.pickEndTime(context),
                suffix: const Icon(Icons.access_time_rounded,
                    size: 18, color: AppColors.onSurfaceVariant),
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

/// Opens the question builder as a keyboard-aware bottom sheet.
Future<void> _openQuestionBuilder(
    BuildContext context, CreateExamController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => _QuestionBuilderSheet(onAdd: controller.addQuestion),
  );
}

/// Multi-type question composer. Multiple-choice shows four option fields with
/// a "correct" selector; true/false shows a True/False selector; essay is just
/// a prompt.
class _QuestionBuilderSheet extends StatefulWidget {
  final ValueChanged<ExamQuestion> onAdd;
  const _QuestionBuilderSheet({required this.onAdd});

  @override
  State<_QuestionBuilderSheet> createState() => _QuestionBuilderSheetState();
}

class _QuestionBuilderSheetState extends State<_QuestionBuilderSheet> {
  ExamQuestionType _type = ExamQuestionType.mcq;
  final _promptCtrl = TextEditingController();
  final _optionCtrls = List.generate(4, (_) => TextEditingController());
  int _correct = 0;
  String? _error;

  @override
  void dispose() {
    _promptCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'Enter the question prompt.');
      return;
    }
    late final ExamQuestion q;
    switch (_type) {
      case ExamQuestionType.mcq:
        final options = _optionCtrls
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (options.length < 2) {
          setState(() => _error = 'Add at least two answer options.');
          return;
        }
        q = ExamQuestion(
          type: ExamQuestionType.mcq,
          prompt: prompt,
          options: options,
          correctIndex: _correct < options.length ? _correct : 0,
        );
      case ExamQuestionType.trueFalse:
        q = ExamQuestion(
          type: ExamQuestionType.trueFalse,
          prompt: prompt,
          options: const ['True', 'False'],
          correctIndex: _correct <= 1 ? _correct : 0,
        );
      case ExamQuestionType.essay:
        q = ExamQuestion(type: ExamQuestionType.essay, prompt: prompt);
    }
    widget.onAdd(q);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text('New Question',
                  style: AppTypography.headlineLg.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Question Type',
                  style:
                      AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.stackSm,
                children: [
                  for (final t in ExamQuestionType.values)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: _type == t,
                      onSelected: (_) => setState(() {
                        _type = t;
                        _correct = 0;
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              PortalFormField(
                label: 'Question Prompt',
                hint: 'Type the question…',
                controller: _promptCtrl,
                maxLines: 2,
              ),
              if (_type == ExamQuestionType.mcq) ...[
                const SizedBox(height: AppSpacing.stackMd),
                Text('Answer Options (tap the circle to mark the correct one)',
                    style: AppTypography.bodySm),
                const SizedBox(height: 6),
                for (var i = 0; i < _optionCtrls.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _correct = i),
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _correct == i
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: _correct == i
                                  ? AppColors.primary
                                  : AppColors.outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Expanded(
                          child: PortalFormField(
                            label: 'Option ${i + 1}',
                            hint: 'Answer choice',
                            controller: _optionCtrls[i],
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else if (_type == ExamQuestionType.trueFalse) ...[
                const SizedBox(height: AppSpacing.stackMd),
                Text('Correct Answer',
                    style: AppTypography.titleMd
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                        child: ChoiceChip(
                          label: Text(i == 0 ? 'True' : 'False'),
                          selected: _correct == i,
                          onSelected: (_) => setState(() => _correct = i),
                        ),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Text(_error!,
                    style: AppTypography.bodySm.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.stackLg),
              PrimaryButton(
                label: 'Add Question',
                leadingIcon: Icons.add,
                trailingIcon: null,
                expanded: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
