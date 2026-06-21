import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/school.dart';

/// Drives the Edit School Profile screen: two tabs (General / Subscription),
/// prefilled form fields, institution-type selection, and suspend toggle.
class EditSchoolController extends GetxController {
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
    registrationCtrl.text = 'REG-992-BCA';
    establishedCtrl.text = '1998';
    phoneCtrl.text = '+1 (555) 123-4567';
    emailCtrl.text = 'admin@oakridge.edu';
    addressCtrl.text = '1245 Education Way, Suite 400';
    cityCtrl.text = school.location.split(',').first;
    stateCtrl.text = 'CA';
    postalCtrl.text = '94103';
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

  Future<void> save() async {
    saving.value = true;
    // TODO: PUT updated school to the API.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    saving.value = false;
    dirty.value = false;
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
