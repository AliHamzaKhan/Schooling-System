import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../ui/admin_widgets/admin_text_field.dart';
import '../../models/payment_mode.dart';
import '../controller/create_school_controller.dart';
import '../../../../ui/admin_theme.dart';

/// Wizard step — how the school pays us for their subscription. Optional, stored
/// in the backend `settings.billing` blob so the admin remembers the
/// arrangement (we don't collect subscription payments online).
class StepPaymentMode extends StatefulWidget {
  final CreateSchoolController controller;
  const StepPaymentMode({super.key, required this.controller});

  @override
  State<StepPaymentMode> createState() => _StepPaymentModeState();
}

class _StepPaymentModeState extends State<StepPaymentMode> with ScreenTextControllers {
  CreateSchoolController get controller => widget.controller;

  // This step owns its fields: created when the step is shown,
  // disposed when the wizard moves on. The values live on the
  // controller, so navigating back and forth keeps what was typed.
  late final _bankNameCtrl = boundController(controller.bankName);
  late final _accountTitleCtrl = boundController(controller.accountTitle);
  late final _accountNumberCtrl = boundController(controller.accountNumber);
  late final _paymentNotesCtrl = boundController(controller.paymentNotes);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Mode',
            style: AdminType.screenTitle.copyWith(fontSize: 24)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'How will this school pay for their subscription? Recorded for your '
          'reference — collection is handled manually.',
          style: AdminType.body,
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
                controller: _bankNameCtrl,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AdminTextField(
                label: 'Account Title',
                hint: 'Name on the account',
                controller: _accountTitleCtrl,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              AdminTextField(
                label: 'Account Number / IBAN',
                hint: 'e.g. PK00 MEZN 0000 0000 0000',
                controller: _accountNumberCtrl,
              ),
            ],
          );
        }),
        const SizedBox(height: AppSpacing.stackLg),
        AdminTextField(
          label: 'Notes (optional)',
          hint: 'Any billing arrangement details to remember…',
          controller: _paymentNotesCtrl,
          maxLines: 3,
        ),
      ],
    );
  }
}
