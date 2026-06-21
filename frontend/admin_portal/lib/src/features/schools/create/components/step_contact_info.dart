import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../controller/create_school_controller.dart';

/// Wizard step 2 — Contact & Location details.
class StepContactInfo extends StatelessWidget {
  final CreateSchoolController controller;
  const StepContactInfo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact & Location',
            style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text('How families and the platform reach this institution.',
            style: AppTypography.bodyLg),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Primary Phone',
          hint: '+1 (555) 123-4567',
          controller: controller.phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Official Email',
          hint: 'admin@school.edu',
          controller: controller.emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Physical Address',
          hint: '1245 Education Way, Suite 400',
          controller: controller.addressCtrl,
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'City',
          hint: 'San Francisco',
          controller: controller.cityCtrl,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminTextField(
                label: 'State / Region',
                hint: 'CA',
                controller: controller.stateCtrl,
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: AdminTextField(
                label: 'Postal Code',
                hint: '94103',
                controller: controller.postalCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
