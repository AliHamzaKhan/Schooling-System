import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Drives the 3-step "New School Profile" wizard.
class CreateSchoolController extends GetxController {
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

  Future<void> _submit() async {
    submitting.value = true;
    // TODO: POST the new school to the API.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    submitting.value = false;
    Get.back<bool>(result: true);
    Get.snackbar('School created', '${nameCtrl.text} has been added.',
        snackPosition: SnackPosition.BOTTOM);
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
