import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/numbered_stepper.dart';
import '../components/step_contact_info.dart';
import '../components/step_initial_plan.dart';
import '../components/step_school_details.dart';
import '../controller/create_school_controller.dart';

/// New School Profile — a 3-step wizard (details → contact → plan).
class CreateSchoolView extends GetView<CreateSchoolController> {
  const CreateSchoolView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackSm, AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
                ),
                Text(controller.title,
                    style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackXl),
            child: Obx(() => NumberedStepper(
                  steps: CreateSchoolController.steps,
                  current: controller.step.value,
                )),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Expanded(
            child: Obx(() {
              final content = switch (controller.step.value) {
                0 => StepSchoolDetails(controller: controller),
                1 => StepContactInfo(controller: controller),
                _ => StepInitialPlan(controller: controller),
              };
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackLg),
                child: GlassSurface(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: content,
                ),
              );
            }),
          ),
          _BottomBar(controller: controller),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CreateSchoolController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPaddingMobile, AppSpacing.stackSm, AppSpacing.containerPaddingMobile, AppSpacing.stackSm),
        child: Column(
          children: [
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
                  label: controller.primaryLabel,
                  expanded: true,
                  isLoading: controller.submitting.value,
                  onPressed: controller.next,
                )),
            const SizedBox(height: AppSpacing.stackSm),
            Obx(() => TextButton(
                  onPressed: controller.back,
                  child: Text(
                    controller.step.value == 0 ? 'Cancel' : 'Back',
                    style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
