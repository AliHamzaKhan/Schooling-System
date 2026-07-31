import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../controller/create_school_controller.dart';

/// Wizard step 4 (create only) — provision the school's Headmaster account.
class StepHeadmaster extends StatelessWidget {
  final CreateSchoolController controller;
  const StepHeadmaster({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Headmaster Account',
            style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('Create the administrator who will manage this school.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Full Name',
          hint: 'Jane Doe',
          controller: controller.hmNameCtrl,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Email',
          hint: 'head@school.edu',
          controller: controller.hmEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Password', style: AppTypography.labelMd),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: controller.hmPasswordCtrl,
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
          controller: controller.hmPhoneCtrl,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
