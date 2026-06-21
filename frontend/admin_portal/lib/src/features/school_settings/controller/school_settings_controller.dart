import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/school_settings_models.dart';

/// Drives School Settings: loads the current config into form fields and
/// persists edits. Text inputs use [TextEditingController]s; dropdowns and
/// switches are observable.
class SchoolSettingsController extends GetxController {
  final SchoolSettingsRepository _repo;
  SchoolSettingsController({SchoolSettingsRepository? repo})
      : _repo = repo ?? SchoolSettingsRepository();

  final loading = true.obs;
  final saving = false.obs;

  final nameCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  final timezone = RxnString();
  final gradingScale = RxnString();
  final guardianRegistration = false.obs;
  final publicResults = false.obs;
  final smsNotifications = false.obs;

  List<String> get timezones => SchoolSettingsRepository.timezones;
  List<String> get gradingScales => SchoolSettingsRepository.gradingScales;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.load();
    final s = res.data;
    if (res.success && s != null) {
      nameCtrl.text = s.name;
      yearCtrl.text = s.academicYear;
      emailCtrl.text = s.contactEmail;
      timezone.value = s.timezone;
      gradingScale.value = s.gradingScale;
      guardianRegistration.value = s.guardianRegistration;
      publicResults.value = s.publicResults;
      smsNotifications.value = s.smsNotifications;
    }
    loading.value = false;
  }

  Future<void> save() async {
    saving.value = true;
    final settings = SchoolSettings(
      name: nameCtrl.text.trim(),
      academicYear: yearCtrl.text.trim(),
      timezone: timezone.value ?? timezones.first,
      gradingScale: gradingScale.value ?? gradingScales.first,
      contactEmail: emailCtrl.text.trim(),
      guardianRegistration: guardianRegistration.value,
      publicResults: publicResults.value,
      smsNotifications: smsNotifications.value,
    );
    await _repo.save(settings);
    saving.value = false;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    yearCtrl.dispose();
    emailCtrl.dispose();
    super.onClose();
  }
}
