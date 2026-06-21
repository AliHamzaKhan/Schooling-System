import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../ui/admin_widgets/admin_text_field.dart';
import '../../../ui/admin_widgets/admin_top_bar.dart';
import '../../../ui/admin_widgets/section_header.dart';
import '../../../ui/admin_widgets/setting_switch_tile.dart';
import '../controller/school_settings_controller.dart';

/// School Settings — general configuration form: identity, academic year,
/// timezone, grading scale, contact, plus policy toggles. Clean report-style
/// grouped cards with a sticky Save action.
class SchoolSettingsView extends GetView<SchoolSettingsController> {
  const SchoolSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTopBar(
            title: 'School Settings',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onSurface),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerPaddingMobile,
                    0,
                    AppSpacing.containerPaddingMobile,
                    AppSpacing.stackXl),
                children: [
                  const SectionHeader(title: 'General'),
                  const SizedBox(height: AppSpacing.stackMd),
                  GlassSurface(
                    child: Column(
                      children: [
                        AdminTextField(
                            label: 'School Name',
                            controller: controller.nameCtrl,
                            required: true),
                        const SizedBox(height: AppSpacing.stackMd),
                        AdminTextField(
                            label: 'Academic Year',
                            hint: '2025 / 2026',
                            controller: controller.yearCtrl),
                        const SizedBox(height: AppSpacing.stackMd),
                        AdminTextField(
                            label: 'Contact Email',
                            controller: controller.emailCtrl,
                            keyboardType: TextInputType.emailAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Localization & Grading'),
                  const SizedBox(height: AppSpacing.stackMd),
                  GlassSurface(
                    child: Column(
                      children: [
                        Obx(() => AdminDropdownField<String>(
                              label: 'Timezone',
                              value: controller.timezone.value,
                              items: controller.timezones,
                              labelOf: (t) => t,
                              onChanged: (v) => controller.timezone.value = v,
                            )),
                        const SizedBox(height: AppSpacing.stackMd),
                        Obx(() => AdminDropdownField<String>(
                              label: 'Grading Scale',
                              value: controller.gradingScale.value,
                              items: controller.gradingScales,
                              labelOf: (g) => g,
                              onChanged: (v) =>
                                  controller.gradingScale.value = v,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  const SectionHeader(title: 'Policies'),
                  const SizedBox(height: AppSpacing.stackMd),
                  GlassSurface(
                    child: Column(
                      children: [
                        Obx(() => SettingSwitchTile(
                              icon: Icons.how_to_reg_outlined,
                              title: 'Guardian Self-Registration',
                              subtitle:
                                  'Let guardians create their own accounts',
                              value: controller.guardianRegistration.value,
                              onChanged: (v) =>
                                  controller.guardianRegistration.value = v,
                            )),
                        const Divider(
                            height: AppSpacing.stackLg,
                            color: AppColors.outlineVariant),
                        Obx(() => SettingSwitchTile(
                              icon: Icons.visibility_outlined,
                              title: 'Publish Results to Guardians',
                              subtitle:
                                  'Show results in the parent app on publish',
                              value: controller.publicResults.value,
                              onChanged: (v) =>
                                  controller.publicResults.value = v,
                            )),
                        const Divider(
                            height: AppSpacing.stackLg,
                            color: AppColors.outlineVariant),
                        Obx(() => SettingSwitchTile(
                              icon: Icons.sms_outlined,
                              title: 'SMS Notifications',
                              subtitle: 'Send alerts over SMS in addition to push',
                              value: controller.smsNotifications.value,
                              onChanged: (v) =>
                                  controller.smsNotifications.value = v,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  Obx(() => PrimaryButton(
                        label: 'Save Settings',
                        expanded: true,
                        leadingIcon: Icons.save_outlined,
                        isLoading: controller.saving.value,
                        onPressed: () async {
                          await controller.save();
                          Get.snackbar('Saved', 'School settings updated.',
                              snackPosition: SnackPosition.BOTTOM);
                        },
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
