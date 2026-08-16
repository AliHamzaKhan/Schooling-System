import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../../quiz/models/quiz_models.dart' show IdLabel;
import '../controller/create_homework_controller.dart';

/// Create Homework — minimal form: title, description, class, due date, points,
/// then a Post Homework primary action. Status-amber left rail on each
/// section card.
class CreateHomeworkView extends StatefulWidget {
  const CreateHomeworkView({super.key});

  @override
  State<CreateHomeworkView> createState() => _CreateHomeworkViewState();
}

class _CreateHomeworkViewState extends State<CreateHomeworkView>
    with ScreenTextControllers {
  final controller = Get.find<CreateHomeworkController>();

  // Every field on this screen gets its own controller, owned here.
  late final _titleCtrl = boundController(controller.title);
  late final _descriptionCtrl = boundController(controller.description);
  late final _dueCtrl = boundController(controller.dueText);
  late final _pointsCtrl = boundController(controller.points);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalTopBar(title: 'Teacher Portal', onBell: () => Get.back<void>()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPaddingMobile,
                  0,
                  AppSpacing.containerPaddingMobile,
                  AppSpacing.stackXl),
              children: [
                Text('Create Homework',
                    style:
                        AppTypography.displayLg.copyWith(fontSize: 30)),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Design a new assignment for your students.',
                    style: AppTypography.bodyLg),
                const SizedBox(height: AppSpacing.stackLg),
                GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    children: [
                      PortalFormField(
                        label: 'Task Title',
                        hint: 'e.g., Algebra Chapter 4 Review',
                        controller: _titleCtrl,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      PortalFormField(
                        label: 'Description & Instructions',
                        hint: 'Provide clear instructions for the students…',
                        controller: _descriptionCtrl,
                        maxLines: 5,
                        filled: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _LogisticsCard(
                  controller: controller,
                  dueCtrl: _dueCtrl,
                  pointsCtrl: _pointsCtrl,
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Obx(() {
                  final err = controller.error.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                    child: Text(err,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.error)),
                  );
                }),
                Obx(() => PrimaryButton(
                      label: 'Post Homework',
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
      ),
    );
  }
}

class _LogisticsCard extends StatelessWidget {
  final CreateHomeworkController controller;

  // Owned by [CreateHomeworkView]'s State — this card only borrows them for as
  // long as it is on screen, and never disposes them.
  final TextEditingController dueCtrl;
  final TextEditingController pointsCtrl;

  const _LogisticsCard({
    required this.controller,
    required this.dueCtrl,
    required this.pointsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFE8A317),
                borderRadius: BorderRadius.horizontal(
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
                    Obx(() => PortalDropdownField<String>(
                          label: 'Assign To Section',
                          hint: controller.loadingOptions.value
                              ? 'Loading…'
                              : 'Select a section',
                          value: controller.selectedSection.value,
                          items: controller.sections.map((s) => s.id).toList(),
                          labelOf: (id) => controller.sections
                              .firstWhere((s) => s.id == id,
                                  orElse: () => controller.sections.isEmpty
                                      ? const IdLabel('', '')
                                      : controller.sections.first)
                              .label,
                          onChanged: controller.selectSection,
                        )),
                    const SizedBox(height: AppSpacing.stackLg),
                    Obx(() => PortalDropdownField<String>(
                          label: 'Subject',
                          hint: controller.loadingOptions.value
                              ? 'Loading…'
                              : 'Select a subject',
                          value: controller.selectedSubject.value,
                          items: controller.subjects.map((s) => s.id).toList(),
                          labelOf: (id) => controller.subjects
                              .firstWhere((s) => s.id == id,
                                  orElse: () => controller.subjects.isEmpty
                                      ? const IdLabel('', '')
                                      : controller.subjects.first)
                              .label,
                          onChanged: controller.selectSubject,
                        )),
                    const SizedBox(height: AppSpacing.stackLg),
                    PortalFormField(
                      label: 'Due Date',
                      hint: 'mm/dd/yyyy',
                      controller: dueCtrl,
                      readOnly: true,
                      onTap: () => controller.pickDueDate(context),
                      suffix: const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 110,
                          child: PortalFormField(
                            label: 'Total Points',
                            hint: '100',
                            controller: pointsCtrl,
                            keyboardType: TextInputType.number,
                            filled: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text('pts', style: AppTypography.bodyLg),
                        ),
                      ],
                    ),
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
