import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/numbered_stepper.dart';
import '../components/step_contact_info.dart';
import '../components/step_headmaster.dart';
import '../components/step_initial_plan.dart';
import '../components/step_payment_mode.dart';
import '../components/step_school_details.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';
import '../../../../ui/admin_widgets/admin_surface.dart';

/// New School Profile — a wizard (details → contact → subscription →
/// headmaster). Edit mode drops the headmaster step.
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
                  icon: const Icon(AppIcons.closeRounded, color: AdminPalette.ink),
                ),
                Text(controller.title,
                    style: AdminType.cardTitle.copyWith(
                        color: AdminPalette.ink, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackXl),
            child: Obx(() => NumberedStepper(
                  steps: controller.steps,
                  current: controller.step.value,
                )),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Expanded(
            child: Obx(() {
              // Route by step label (not index) — the Payment Mode step sits
              // between Subscription and Headmaster, and edit mode omits the
              // Headmaster step entirely.
              final content = switch (controller.steps[controller.step.value]) {
                'School Details' => StepSchoolDetails(controller: controller),
                'Contact Info' => StepContactInfo(controller: controller),
                'Subscription' => StepInitialPlan(controller: controller),
                'Payment Mode' => StepPaymentMode(controller: controller),
                _ => StepHeadmaster(controller: controller),
              };
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile, 0, AppSpacing.containerPaddingMobile, AppSpacing.stackLg),
                child: AdminCard(
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
                    style: AdminType.meta.copyWith(color: AdminPalette.danger)),
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
                    style: AdminType.label.copyWith(color: AdminPalette.muted),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
