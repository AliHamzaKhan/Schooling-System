import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../../../ui/admin_widgets/logo_upload_box.dart';
import '../controller/create_school_controller.dart';

/// Wizard step 1 — General Information (logo, name, type, registration, motto).
class StepSchoolDetails extends StatelessWidget {
  final CreateSchoolController controller;
  const StepSchoolDetails({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General Information', style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Establish the primary identity and settings for the new educational institution.',
          style: AppTypography.bodyLg,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('School Logo',
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: 6),
        LogoUploadBox(onTap: () {}),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Official School Name',
          hint: 'e.g. Springfield Elementary',
          controller: controller.nameCtrl,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Obx(() => AdminDropdownField<String>(
              label: 'Institution Type',
              hint: 'Select type…',
              value: controller.institutionType.value,
              items: CreateSchoolController.institutionTypes,
              labelOf: (t) => t,
              onChanged: controller.selectInstitutionType,
            )),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Registration / ID Number',
          hint: 'e.g. REG-2024-890',
          controller: controller.registrationCtrl,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Brief Description / Motto',
          hint: "A short description of the school's mission or motto…",
          controller: controller.descriptionCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
