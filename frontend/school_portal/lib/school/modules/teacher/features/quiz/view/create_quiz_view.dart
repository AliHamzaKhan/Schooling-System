import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../controller/create_quiz_controller.dart';
import '../models/quiz_models.dart';

/// Create Quiz — title + section/subject pickers, an MCQ question builder, a
/// running total, and a Save & Publish action.
class CreateQuizView extends GetView<CreateQuizController> {
  const CreateQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Create Quiz')),
      body: Obx(() {
        if (controller.loadingOptions.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPaddingMobile,
              AppSpacing.stackMd,
              AppSpacing.containerPaddingMobile,
              120),
          children: [
            GlassInput(
                label: 'Quiz title',
                hint: 'e.g. Chapter 3 — Fractions',
                controller: controller.titleCtrl),
            const SizedBox(height: AppSpacing.stackMd),
            Obx(() => ActionDropdownField<String>(
                  label: 'Section',
                  hint: 'Select a section',
                  value: controller.selectedSection.value,
                  items: [
                    for (final s in controller.sections)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  onChanged: controller.selectSection,
                )),
            const SizedBox(height: AppSpacing.stackMd),
            Obx(() => ActionDropdownField<String>(
                  label: 'Subject',
                  hint: 'Select a subject',
                  value: controller.selectedSubject.value,
                  items: [
                    for (final s in controller.subjects)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  onChanged: controller.selectSubject,
                )),
            const SizedBox(height: AppSpacing.stackLg),

            // Assignment target.
            Text('Assign to', style: AppTypography.titleMd),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Row(
                  children: [
                    _Chip(
                      label: 'Whole class',
                      selected: controller.assignToWholeClass.value,
                      onTap: () => controller.setAssignToWholeClass(true),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    _Chip(
                      label: 'Specific students',
                      selected: !controller.assignToWholeClass.value,
                      onTap: () => controller.setAssignToWholeClass(false),
                    ),
                  ],
                )),
            Obx(() {
              if (controller.assignToWholeClass.value) {
                return const SizedBox.shrink();
              }
              if (controller.selectedSection.value == null) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackSm),
                  child: Text('Pick a section first.',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                );
              }
              if (controller.loadingRoster.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.stackMd),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.roster.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackSm),
                  child: Text('No students enrolled in this section.',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.stackSm),
                child: Wrap(
                  spacing: AppSpacing.stackSm,
                  runSpacing: AppSpacing.stackSm,
                  children: [
                    for (final s in controller.roster)
                      _Chip(
                        label: s.label,
                        selected: controller.selectedStudents.contains(s.id),
                        onTap: () => controller.toggleStudent(s.id),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.stackLg),

            // Questions header + running total.
            Row(
              children: [
                Text('Questions', style: AppTypography.titleLg),
                const Spacer(),
                Obx(() => Text(
                      '${controller.questions.length} · ${_fmt(controller.totalMarks)} marks',
                      style: AppTypography.labelMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => Column(
                  children: [
                    for (var i = 0; i < controller.questions.length; i++) ...[
                      _QuestionTile(
                        index: i,
                        question: controller.questions[i],
                        onDelete: () => controller.removeQuestion(i),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                    ],
                  ],
                )),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => GhostButton(
                  label: controller.generating.value
                      ? 'Generating from PDF…'
                      : 'Generate from PDF (AI)',
                  leadingIcon: Icons.auto_awesome_rounded,
                  trailingIcon: null,
                  expanded: true,
                  onPressed: controller.generating.value
                      ? null
                      : controller.generateFromPdf,
                )),
            const SizedBox(height: AppSpacing.stackSm),
            GhostButton(
              label: 'Add Question',
              leadingIcon: Icons.add,
              trailingIcon: null,
              expanded: true,
              onPressed: () async {
                final q = await _showAddQuestion(context);
                if (q != null) controller.addQuestion(q);
              },
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Obx(() {
              final err = controller.error.value;
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                child: Text(err,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.error)),
              );
            }),
            Obx(() => PrimaryButton(
                  label: 'Save & Publish',
                  leadingIcon: Icons.publish_rounded,
                  trailingIcon: null,
                  expanded: true,
                  isLoading: controller.submitting.value,
                  onPressed: controller.saveAndPublish,
                )),
          ],
        );
      }),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<DraftQuestion?> _showAddQuestion(BuildContext context) {
    return showDialog<DraftQuestion>(
      context: context,
      builder: (_) => const _AddQuestionDialog(),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final int index;
  final DraftQuestion question;
  final VoidCallback onDelete;
  const _QuestionTile({
    required this.index,
    required this.question,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${question.prompt}',
                    style: AppTypography.bodyLg
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Answer: ${question.options[question.correctIndex]}  ·  ${CreateQuizView._fmt(question.marks)} mark(s)',
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.error,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.stackMd, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(label,
            style: AppTypography.labelMd.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            )),
      ),
    );
  }
}

/// Dialog capturing one MCQ: a prompt, up to 4 options, the correct one, marks.
class _AddQuestionDialog extends StatefulWidget {
  const _AddQuestionDialog();

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _prompt = TextEditingController();
  final _marks = TextEditingController(text: '1');
  final _options = List.generate(4, (_) => TextEditingController());
  int _correct = 0;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    _marks.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final prompt = _prompt.text.trim();
    final opts = _options.map((c) => c.text.trim()).toList();
    final filled = [for (var i = 0; i < opts.length; i++) if (opts[i].isNotEmpty) i];
    if (prompt.isEmpty) {
      setState(() => _error = 'Enter the question.');
      return;
    }
    if (filled.length < 2) {
      setState(() => _error = 'Add at least two options.');
      return;
    }
    if (!filled.contains(_correct)) {
      setState(() => _error = 'Mark the correct option (it must be filled in).');
      return;
    }
    final marks = double.tryParse(_marks.text.trim()) ?? 1;
    if (marks <= 0) {
      setState(() => _error = 'Marks must be greater than zero.');
      return;
    }
    // Compact to only the filled options, remapping the correct index.
    final keptOptions = [for (final i in filled) opts[i]];
    final newCorrect = filled.indexOf(_correct);
    Navigator.of(context).pop(DraftQuestion(
      prompt: prompt,
      options: keptOptions,
      correctIndex: newCorrect,
      marks: marks,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassInput(
                label: 'Question', hint: 'Type the question', controller: _prompt),
            const SizedBox(height: AppSpacing.stackSm),
            Text('Options (tap the circle to mark the correct one)',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _correct = i),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        i == _correct
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: i == _correct
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.stackSm),
            SizedBox(
              width: 120,
              child: GlassInput(
                label: 'Marks',
                hint: '1',
                controller: _marks,
                keyboardType: TextInputType.number,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Text(_error!,
                  style: AppTypography.bodySm.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
