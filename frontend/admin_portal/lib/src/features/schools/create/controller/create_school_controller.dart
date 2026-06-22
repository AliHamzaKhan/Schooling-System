import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/school.dart';
import '../../models/schools_repository.dart';

/// Drives the 3-step school wizard, used for BOTH creating a new school and
/// editing an existing one. Pass a [School] via `Get.arguments` to enter edit
/// mode: the fields are prefilled and submit issues updates instead of a create.
class CreateSchoolController extends GetxController {
  final SchoolsRepository _repo = SchoolsRepository();

  /// The school being edited, or null in create mode (set from `Get.arguments`).
  School? editing;
  bool get isEdit => editing != null;

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
  String get title => isEdit ? 'Edit School Profile' : 'New School Profile';
  String get primaryLabel =>
      isLast ? (isEdit ? 'Save Changes' : 'Create School') : 'Next Step';

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is School) {
      editing = arg;
      _prefill(arg);
    }
  }

  /// Prefills every step from the school being edited.
  void _prefill(School s) {
    nameCtrl.text = s.name;
    registrationCtrl.text = s.code;
    emailCtrl.text = s.contactEmail ?? '';
    phoneCtrl.text = s.contactPhone ?? '';
    addressCtrl.text = s.address ?? '';
    selectedPlan.value = _planLabel(s.planCode);
  }

  /// Backend plan code → UI plan label (inverse of [_planCode]).
  static String _planLabel(String? code) => switch (code) {
        'basic' => 'Basic',
        'premium' => 'Enterprise',
        _ => 'Pro', // 'standard' / unknown
      };

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

    if (isEdit) {
      await _submitEdit(addr);
    } else {
      await _submitCreate(addr);
    }
    submitting.value = false;
  }

  Future<void> _submitCreate(String addr) async {
    final payload = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'code': _code(),
      if (emailCtrl.text.trim().isNotEmpty) 'contact_email': emailCtrl.text.trim(),
      if (phoneCtrl.text.trim().isNotEmpty) 'contact_phone': phoneCtrl.text.trim(),
      if (addr.isNotEmpty) 'address': addr,
      'subscription_plan_code': _planCode(selectedPlan.value),
    };
    final res = await _repo.create(payload);
    if (res.success) {
      Get.back<bool>(result: true);
      Get.snackbar('School created', '${nameCtrl.text} has been added.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      error.value = res.error ?? 'Could not create the school. Try again.';
    }
  }

  Future<void> _submitEdit(String addr) async {
    final id = editing!.id;
    // `code` is not editable via SchoolUpdate; update general info only.
    final res = await _repo.update(id, {
      'name': nameCtrl.text.trim(),
      'contact_email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'contact_phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      if (addr.isNotEmpty) 'address': addr,
    });
    if (!res.success) {
      error.value = res.error ?? 'Could not save changes. Try again.';
      return;
    }
    // Apply a plan change if the selection differs from the current plan.
    final newPlan = _planCode(selectedPlan.value);
    if (newPlan != editing!.planCode) {
      final planRes = await _repo.assignSubscription(id, newPlan);
      if (!planRes.success) {
        error.value = planRes.error ?? 'Saved details, but plan update failed.';
        return;
      }
    }
    Get.back<bool>(result: true);
    Get.snackbar('Saved', 'School profile updated.',
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
