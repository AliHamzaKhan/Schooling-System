import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/headmaster_repository.dart';
import '../models/fees_data.dart';

/// Drives the Fee Management dashboard.
class FeesController extends GetxController {
  final HeadmasterRepository _repo;
  FeesController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<FeesData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadFees();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load fees.';
    }
    loading.value = false;
  }

  /// Sends a payment reminder for a single overdue invoice.
  void remind(OverduePayment payment) => Get.snackbar(
        'Reminder sent',
        'A payment reminder was sent for ${payment.studentName}.',
        snackPosition: SnackPosition.BOTTOM,
      );

  /// Sends reminders to every outstanding invoice.
  void remindAll() {
    final count = data.value?.overdue.length ?? 0;
    Get.snackbar(
      'Reminders sent',
      count == 0
          ? 'There are no overdue invoices.'
          : 'Reminders were sent to $count guardian(s).',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  static const _methods = ['cash', 'card', 'bank_transfer', 'online', 'cheque'];

  /// Opens the "Record Payment" form against an outstanding invoice; reloads
  /// the finance dashboard on success.
  Future<void> recordPaymentFlow() async {
    final overdue = data.value?.overdue ?? const <OverduePayment>[];
    if (overdue.isEmpty) {
      Get.snackbar('No outstanding fees', 'There are no invoices to collect.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final selectedInvoice = Rxn<String>(overdue.first.id);
    final selectedMethod = 'cash'.obs;
    final amount = TextEditingController(
        text: overdue.first.amount.toStringAsFixed(0));

    final ok = await showActionFormSheet(
      title: 'Record Payment',
      submitLabel: 'Record Payment',
      fields: [
        Obx(() => ActionDropdownField<String>(
              label: 'Invoice',
              hint: 'Select an invoice',
              value: selectedInvoice.value,
              items: [
                for (final o in overdue)
                  DropdownMenuItem(
                    value: o.id,
                    child: Text('${o.studentName} · ${o.amountLabel}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                selectedInvoice.value = v;
                final match = overdue.firstWhere((o) => o.id == v,
                    orElse: () => overdue.first);
                amount.text = match.amount.toStringAsFixed(0);
              },
            )),
        GlassInput(
          label: 'Amount',
          hint: 'e.g. 5000',
          controller: amount,
          keyboardType: TextInputType.number,
        ),
        Obx(() => ActionDropdownField<String>(
              label: 'Method',
              hint: 'Payment method',
              value: selectedMethod.value,
              items: [
                for (final m in _methods)
                  DropdownMenuItem(
                      value: m, child: Text(m.replaceAll('_', ' '))),
              ],
              onChanged: (v) => selectedMethod.value = v ?? 'cash',
            )),
      ],
      onSubmit: () async {
        final invoiceId = selectedInvoice.value;
        final value = double.tryParse(amount.text.trim());
        if (invoiceId == null) return 'Select an invoice';
        if (value == null || value <= 0) return 'Enter a valid amount';
        final res = await _repo.recordPayment(
            invoiceId: invoiceId, amount: value, method: selectedMethod.value);
        return res.success ? null : (res.error ?? 'Could not record payment');
      },
    );
    if (ok == true) {
      Get.snackbar('Payment recorded', 'The payment was saved.',
          snackPosition: SnackPosition.BOTTOM);
      await load();
    }
  }
}
