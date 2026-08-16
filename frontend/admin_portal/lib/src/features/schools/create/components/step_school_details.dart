import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../../../ui/admin_widgets/logo_upload_box.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';

/// Wizard step 1 — General Information (logo, name, type, registration, motto).
class StepSchoolDetails extends StatefulWidget {
  final CreateSchoolController controller;
  const StepSchoolDetails({super.key, required this.controller});

  @override
  State<StepSchoolDetails> createState() => _StepSchoolDetailsState();
}

class _StepSchoolDetailsState extends State<StepSchoolDetails> with ScreenTextControllers {
  CreateSchoolController get controller => widget.controller;

  // This step owns its fields: created when the step is shown,
  // disposed when the wizard moves on. The values live on the
  // controller, so navigating back and forth keeps what was typed.
  late final _nameCtrl = boundController(controller.name);
  late final _registrationCtrl = boundController(controller.registration);
  late final _descriptionCtrl = boundController(controller.description);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General Information', style: AdminType.screenTitle.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Establish the primary identity and settings for the new educational institution.',
          style: AdminType.body,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('School Logo',
            style: AdminType.label.copyWith(color: AdminPalette.ink)),
        const SizedBox(height: 6),
        LogoUploadBox(onTap: () {}),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Official School Name',
          hint: 'e.g. Springfield Elementary',
          controller: _nameCtrl,
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
          controller: _registrationCtrl,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Brief Description / Motto',
          hint: "A short description of the school's mission or motto…",
          controller: _descriptionCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
