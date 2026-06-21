import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/schools_repository.dart';

/// Drives the 3-step "New School Profile" wizard.
class CreateSchoolController extends GetxController {
  final SchoolsRepository _repo = SchoolsRepository();

  static const steps = ['School Details', 'Contact Info', 'Initial Plan'];
  static const institutionTypes = [
    'Public School',
    'Private School',
    'Charter School',
    'International',
    'Other',
  ];
  static const plans = ['Basic', 'Pro', 'Enterprise'];

  final step = 0.obs;
  final submitting = false.obs;

  // Step 1 — details.
  final nameCtrl = TextEditingController();
  final registrationCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final institutionType = RxnString();

  // Step 2 — contact.
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final postalCtrl = TextEditingController();

  // Step 3 — plan.
  final selectedPlan = 'Pro'.obs;

  final error = RxnString();

  bool get isLast => step.value == steps.length - 1;
  String get primaryLabel => isLast ? 'Create School' : 'Next Step';

  void selectInstitutionType(String? v) => institutionType.value = v;
  void selectPlan(String p) => selectedPlan.value = p;

  void next() {
    error.value = null;
    if (step.value == 0 && nameCtrl.text.trim().isEmpty) {
      error.value = 'Official school name is required.';
      return;
    }
    if (isLast) {
      _submit();
      return;
    }
    step.value++;
  }

  void back() {
    error.value = null;
    if (step.value == 0) {
      Get.back<void>();
    } else {
      step.value--;
    }
  }

  /// Maps the UI plan label to the backend `PlanCode`.
  static String _planCode(String label) => switch (label) {
        'Basic' => 'basic',
        'Enterprise' => 'premium',
        _ => 'standard', // 'Pro'
      };

  /// Backend `code` is required (min 2 chars). Use the registration number when
  /// provided, otherwise derive a slug from the name.
  String _code() {
    final reg = registrationCtrl.text.trim();
    if (reg.length >= 2) return reg;
    final slug = nameCtrl.text
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.length >= 2 ? slug : 'SCH-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _submit() async {
    submitting.value = true;
    error.value = null;
    final addr = [
      addressCtrl.text.trim(),
      cityCtrl.text.trim(),
      stateCtrl.text.trim(),
      postalCtrl.text.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    final payload = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'code': _code(),
      if (emailCtrl.text.trim().isNotEmpty) 'contact_email': emailCtrl.text.trim(),
      if (phoneCtrl.text.trim().isNotEmpty) 'contact_phone': phoneCtrl.text.trim(),
      if (addr.isNotEmpty) 'address': addr,
      'subscription_plan_code': _planCode(selectedPlan.value),
    };
    final res = await _repo.create(payload);
    submitting.value = false;
    if (res.success) {
      Get.back<bool>(result: true);
      Get.snackbar('School created', '${nameCtrl.text} has been added.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      error.value = res.error ?? 'Could not create the school. Try again.';
    }
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      registrationCtrl,
      descriptionCtrl,
      phoneCtrl,
      emailCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl,
      postalCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
