import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/school.dart';
import '../../models/schools_repository.dart';

/// Drives the Edit School Profile screen: two tabs (General / Subscription),
/// prefilled form fields, institution-type selection, and suspend toggle.
class EditSchoolController extends GetxController {
  final SchoolsRepository _repo = SchoolsRepository();

  static const institutionTypes = ['Public', 'Private', 'Charter', 'Other'];

  /// School being edited; passed via `Get.arguments` from the list, with a
  /// sensible fallback so the route is openable standalone.
  late final School school;

  final tab = 0.obs; // 0 = General Info, 1 = Subscription Details
  final dirty = false.obs;
  final saving = false.obs;

  final nameCtrl = TextEditingController();
  final registrationCtrl = TextEditingController();
  final establishedCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final postalCtrl = TextEditingController();

  final institutionType = 'Private'.obs;
  final suspended = false.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    school = arg is School ? arg : _fallback;
    _prefill();
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
  }

  List<TextEditingController> get _controllers => [
        nameCtrl,
        registrationCtrl,
        establishedCtrl,
        phoneCtrl,
        emailCtrl,
        addressCtrl,
        cityCtrl,
        stateCtrl,
        postalCtrl,
      ];

  void _prefill() {
    nameCtrl.text = school.name;
    registrationCtrl.text = school.code;
    establishedCtrl.text = '';
    phoneCtrl.text = school.contactPhone ?? '';
    emailCtrl.text = school.contactEmail ?? '';
    addressCtrl.text = school.address ?? '';
    cityCtrl.text = '';
    stateCtrl.text = '';
    postalCtrl.text = '';
    suspended.value = school.status == SchoolStatus.expired;
  }

  void _markDirty() {
    if (!dirty.value) dirty.value = true;
  }

  void selectTab(int i) => tab.value = i;
  void selectInstitutionType(String t) {
    institutionType.value = t;
    _markDirty();
  }

  void toggleSuspend(bool v) {
    suspended.value = v;
    _markDirty();
  }

  void discard() {
    _prefill();
    institutionType.value = 'Private';
    suspended.value = false;
    dirty.value = false;
  }

  final error = RxnString();

  Future<void> save() async {
    saving.value = true;
    error.value = null;
    final addr = [
      addressCtrl.text.trim(),
      cityCtrl.text.trim(),
      stateCtrl.text.trim(),
      postalCtrl.text.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    final payload = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      'contact_email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'contact_phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      if (addr.isNotEmpty) 'address': addr,
    };

    final res = await _repo.update(school.id, payload);
    if (!res.success) {
      saving.value = false;
      error.value = res.error ?? 'Could not save changes. Try again.';
      return;
    }

    // Reflect the suspend toggle if it changed the school's status.
    final wantSuspended = suspended.value;
    final isSuspended = school.status == SchoolStatus.expired;
    if (wantSuspended != isSuspended) {
      final statusRes =
          await _repo.setStatus(school.id, wantSuspended ? 'suspended' : 'active');
      if (!statusRes.success) {
        saving.value = false;
        error.value = statusRes.error ?? 'Saved details, but status update failed.';
        return;
      }
    }

    saving.value = false;
    dirty.value = false;
    Get.back<bool>(result: true);
    Get.snackbar('Saved', 'School profile updated.',
        snackPosition: SnackPosition.BOTTOM);
  }

  static const _fallback = School(
    id: 'SCH-2023-089',
    name: 'Oakridge International Academy',
    location: 'San Francisco, CA',
    students: 1245,
    status: SchoolStatus.active,
    tenureLabel: 'Joined Aug 2022',
  );

  @override
  void onClose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.onClose();
  }
}
