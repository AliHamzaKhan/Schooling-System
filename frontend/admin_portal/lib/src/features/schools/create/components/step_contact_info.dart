import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';

/// Wizard step 2 — Contact & Location details.
class StepContactInfo extends StatefulWidget {
  final CreateSchoolController controller;
  const StepContactInfo({super.key, required this.controller});

  @override
  State<StepContactInfo> createState() => _StepContactInfoState();
}

class _StepContactInfoState extends State<StepContactInfo> with ScreenTextControllers {
  CreateSchoolController get controller => widget.controller;

  // This step owns its fields: created when the step is shown,
  // disposed when the wizard moves on. The values live on the
  // controller, so navigating back and forth keeps what was typed.
  late final _phoneCtrl = boundController(controller.phone);
  late final _emailCtrl = boundController(controller.email);
  late final _addressCtrl = boundController(controller.address);
  late final _cityCtrl = boundController(controller.city);
  late final _stateCtrl = boundController(controller.stateProvince);
  late final _postalCtrl = boundController(controller.postal);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact & Location',
            style: AdminType.screenTitle.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('How families and the platform reach this institution.',
            style: AdminType.body),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Primary Phone',
          hint: '+1 (555) 123-4567',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Official Email',
          hint: 'admin@school.edu',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Physical Address',
          hint: '1245 Education Way, Suite 400',
          controller: _addressCtrl,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'City',
          hint: 'San Francisco',
          controller: _cityCtrl,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminTextField(
                label: 'State / Region',
                hint: 'CA',
                controller: _stateCtrl,
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: AdminTextField(
                label: 'Postal Code',
                hint: '94103',
                controller: _postalCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
