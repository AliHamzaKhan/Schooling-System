import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/portal_form_field.dart';
import '../../../../../widgets/portal_top_bar.dart';
import '../controller/create_homework_controller.dart';

/// Create Homework — minimal form: title, description, class, due date, points,
/// then a Post Homework primary action. Status-amber left rail on each
/// section card.
class CreateHomeworkView extends GetView<CreateHomeworkController> {
  const CreateHomeworkView({super.key});

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
                        controller: controller.titleCtrl,
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      PortalFormField(
                        label: 'Description & Instructions',
                        hint: 'Provide clear instructions for the students…',
                        controller: controller.descriptionCtrl,
                        maxLines: 5,
                        filled: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                _LogisticsCard(controller: controller),
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
  const _LogisticsCard({required this.controller});

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
                          label: 'Assign To Class',
                          hint: 'Select a class',
                          value: controller.selectedClass.value,
                          items: CreateHomeworkController.classes,
                          labelOf: (s) => s,
                          onChanged: controller.selectClass,
                        )),
                    const SizedBox(height: AppSpacing.stackLg),
                    PortalFormField(
                      label: 'Due Date',
                      hint: 'mm/dd/yyyy',
                      controller: controller.dueCtrl,
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
                            controller: controller.pointsCtrl,
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
