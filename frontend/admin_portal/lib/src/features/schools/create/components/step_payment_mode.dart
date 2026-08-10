import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../models/payment_mode.dart';
import '../controller/create_school_controller.dart';

/// Wizard step — how the school pays us for their subscription. Optional, stored
/// in the backend `settings.billing` blob so the admin remembers the
/// arrangement (we don't collect subscription payments online).
class StepPaymentMode extends StatelessWidget {
  final CreateSchoolController controller;
  const StepPaymentMode({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Mode',
            style: AppTypography.headlineLg.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'How will this school pay for their subscription? Recorded for your '
          'reference — collection is handled manually.',
          style: AppTypography.bodyLg,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        Obx(() => AdminDropdownField<String>(
              label: 'Payment Method',
              hint: 'Select method…',
              value: controller.paymentMethod.value,
              items: PaymentMode.methodCodes,
              labelOf: PaymentMode.label,
              onChanged: controller.selectPaymentMethod,
            )),
        Obx(() {
          if (!PaymentMode.needsBankDetails(controller.paymentMethod.value)) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              const SizedBox(height: AppSpacing.stackLg),
              AdminTextField(
                label: 'Bank Name',
                hint: 'e.g. Meezan Bank',
                controller: controller.bankNameCtrl,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AdminTextField(
                label: 'Account Title',
                hint: 'Name on the account',
                controller: controller.accountTitleCtrl,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AdminTextField(
                label: 'Account Number / IBAN',
                hint: 'e.g. PK00 MEZN 0000 0000 0000',
                controller: controller.accountNumberCtrl,
              ),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Notes (optional)',
          hint: 'Any billing arrangement details to remember…',
          controller: controller.paymentNotesCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
