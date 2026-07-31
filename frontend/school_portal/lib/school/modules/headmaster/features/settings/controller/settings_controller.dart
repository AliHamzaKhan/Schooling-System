import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/school_profile.dart';

/// Drives the headmaster School Settings screen: loads the current profile +
/// branding, then saves edits (name, logo, uniform colour, monthly fee day).
class SettingsController extends GetxController {
  final HeadmasterRepository _repo;
  SettingsController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final saving = false.obs;
  final error = RxnString();

  final name = TextEditingController();
  final logoUrl = TextEditingController();
  final uniformColor = TextEditingController();
  final feeDueDay = TextEditingController();
  final salaryDay = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadSchoolProfile();
    if (res.success && res.data != null) {
      _fill(res.data!);
    } else {
      error.value = res.error ?? 'Could not load school settings.';
    }
    loading.value = false;
  }

  void _fill(SchoolProfile p) {
    name.text = p.name;
    logoUrl.text = p.logoUrl ?? '';
    uniformColor.text = p.uniformColor ?? '';
    feeDueDay.text = p.feeDueDay?.toString() ?? '';
    salaryDay.text = p.salaryDay?.toString() ?? '';
  }

  int? _validDay(TextEditingController c) {
    final raw = c.text.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    return (v != null && v >= 1 && v <= 31) ? v : -1; // -1 = invalid sentinel
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Get.snackbar('Name required', 'School name cannot be empty.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final day = _validDay(feeDueDay);
    if (day == -1) {
      Get.snackbar('Invalid fee day', 'Enter a day between 1 and 31.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final salary = _validDay(salaryDay);
    if (salary == -1) {
      Get.snackbar('Invalid salary day', 'Enter a day between 1 and 31.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    saving.value = true;
    final res = await _repo.saveSchoolProfile(
      name: name.text.trim(),
      logoUrl: logoUrl.text.trim().isEmpty ? null : logoUrl.text.trim(),
      uniformColor:
          uniformColor.text.trim().isEmpty ? null : uniformColor.text.trim(),
      feeDueDay: day,
      salaryDay: salary,
    );
    saving.value = false;
    if (res.success) {
      if (res.data != null) _fill(res.data!);
      Get.snackbar('Settings saved', 'Your school settings were updated.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Could not save', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    name.dispose();
    logoUrl.dispose();
    uniformColor.dispose();
    feeDueDay.dispose();
    salaryDay.dispose();
    super.onClose();
  }
}
