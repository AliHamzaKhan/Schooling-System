import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../../../../widgets/skeletons.dart';
import '../../quiz/models/quiz_models.dart' show IdLabel;
import '../controller/create_exam_controller.dart';

/// Create Exam — name, class, date range, and one or more subject papers
/// (subject + max/pass marks). This mirrors what the backend stores; authoring
/// quiz-style questions lives in the separate Quiz feature.
class CreateExamView extends GetView<CreateExamController> {
  const CreateExamView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalTopBar(title: 'Teacher Portal', onBell: () => Get.back<void>()),
          Expanded(
            child: Obx(() {
              if (controller.loadingOptions.value) {
                return const SkeletonPage(
                    withHeader: false, body: SkeletonForm(fields: 5));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  Text('Create Exam',
                      style: AppTypography.displayLg.copyWith(fontSize: 30)),
                  const SizedBox(height: AppSpacing.stackSm),
                  Text('Schedule an exam and add its subject papers.',
                      style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ── Basics ──
                  GlassSurface(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      children: [
                        PortalFormField(
                          label: 'Exam Name',
                          hint: 'e.g. Mid-Term Examination',
                          controller: controller.nameCtrl,
                        ),
                        const SizedBox(height: AppSpacing.stackLg),
                        Obx(() => PortalDropdownField<String>(
                              label: 'Class',
                              hint: controller.classes.isEmpty
                                  ? 'No classes available'
                                  : 'Select the class',
                              value: controller.selectedClass.value,
                              items: controller.classes
                                  .map((c) => c.id)
                                  .toList(),
                              labelOf: (id) => _labelFor(controller.classes, id),
                              onChanged: controller.selectClass,
                            )),
                        const SizedBox(height: AppSpacing.stackLg),
                        Row(
                          children: [
                            Expanded(
                              child: PortalFormField(
                                label: 'Starts',
                                hint: 'mm/dd/yyyy',
                                controller: controller.startCtrl,
                                readOnly: true,
                                onTap: () =>
                                    controller.pickStartDate(context),
                                suffix: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackMd),
                            Expanded(
                              child: PortalFormField(
                                label: 'Ends',
                                hint: 'mm/dd/yyyy',
                                controller: controller.endCtrl,
                                readOnly: true,
                                onTap: () => controller.pickEndDate(context),
                                suffix: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ── Papers ──
                  Row(
                    children: [
                      Expanded(
                          child: Text('Subject Papers',
                              style: AppTypography.titleLg)),
                      TextButton.icon(
                        onPressed: controller.addPaper,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add paper'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Obx(() => Column(
                        children: [
                          for (var i = 0;
                              i < controller.papers.length;
                              i++) ...[
                            _PaperCard(controller: controller, index: i),
                            const SizedBox(height: AppSpacing.stackSm),
                          ],
                        ],
                      )),
                  const SizedBox(height: AppSpacing.stackLg),

                  Obx(() {
                    final err = controller.error.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.stackSm),
                      child: Text(err,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.error)),
                    );
                  }),
                  Obx(() => PrimaryButton(
                        label: 'Create Exam',
                        leadingIcon: Icons.fact_check_outlined,
                        trailingIcon: null,
                        expanded: true,
                        isLoading: controller.submitting.value,
                        onPressed: controller.save,
                      )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _labelFor(List<IdLabel> items, String id) => items
      .firstWhere((e) => e.id == id,
          orElse: () => items.isEmpty ? const IdLabel('', '') : items.first)
      .label;
}

class _PaperCard extends StatelessWidget {
  final CreateExamController controller;
  final int index;
  const _PaperCard({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    final paper = controller.papers[index];
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PortalDropdownField<String>(
                  label: 'Subject',
                  hint: 'Select a subject',
                  value: paper.subjectId,
                  items: controller.subjects.map((s) => s.id).toList(),
                  labelOf: (id) =>
                      CreateExamView._labelFor(controller.subjects, id),
                  onChanged: (v) => controller.selectPaperSubject(index, v),
                ),
              ),
              if (controller.papers.length > 1)
                IconButton(
                  onPressed: () => controller.removePaper(index),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                child: PortalFormField(
                  label: 'Max marks',
                  hint: '100',
                  controller: paper.maxCtrl,
                  keyboardType: TextInputType.number,
                  filled: true,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: PortalFormField(
                  label: 'Pass marks',
                  hint: '40',
                  controller: paper.passCtrl,
                  keyboardType: TextInputType.number,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
