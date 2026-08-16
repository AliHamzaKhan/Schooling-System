import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';

/// Wizard step 4 (create only) — provision the school's Headmaster account.
class StepHeadmaster extends StatefulWidget {
  final CreateSchoolController controller;
  const StepHeadmaster({super.key, required this.controller});

  @override
  State<StepHeadmaster> createState() => _StepHeadmasterState();
}

class _StepHeadmasterState extends State<StepHeadmaster> with ScreenTextControllers {
  CreateSchoolController get controller => widget.controller;

  // This step owns its fields: created when the step is shown,
  // disposed when the wizard moves on. The values live on the
  // controller, so navigating back and forth keeps what was typed.
  late final _hmNameCtrl = boundController(controller.hmName);
  late final _hmEmailCtrl = boundController(controller.hmEmail);
  late final _hmPasswordCtrl = boundController(controller.hmPassword);
  late final _hmPhoneCtrl = boundController(controller.hmPhone);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Headmaster Account',
            style: AdminType.screenTitle.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Create the administrator who will manage this school.',
            style: AdminType.body),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Full Name',
          hint: 'Jane Doe',
          controller: _hmNameCtrl,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Email',
          hint: 'head@school.edu',
          controller: _hmEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Password', style: AdminType.label),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _hmPasswordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'At least 8 characters',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Phone (optional)',
          hint: '+1 (555) 123-4567',
          controller: _hmPhoneCtrl,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
