import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/school_profile.dart';

typedef SchoolProfileLoader = Future<ApiResponse<SchoolProfile>> Function();

/// Drives the headmaster School Settings screen: loads the current profile +
/// branding, then saves edits (name, logo, uniform colour, monthly fee day).
class SettingsController extends GetxController {
  final HeadmasterRepository _repo;
  final SchoolProfileLoader _loader;
  SettingsController({HeadmasterRepository? repo, SchoolProfileLoader? loader})
    : _repo = repo ?? Get.find<HeadmasterRepository>(),
      _loader =
          loader ??
          (repo ?? Get.find<HeadmasterRepository>()).loadSchoolProfile;

  final loading = true.obs;
  final saving = false.obs;
  final error = RxnString();

  /// Settings values. The `TextEditingController`s for the editable ones are
  /// owned by [SettingsView]'s State, so they are disposed with that screen;
  /// [logoUrl] and [uniformColor] are set by the picker widgets, not typed.
  final name = ''.obs;
  final logoUrl = ''.obs;
  final uniformColor = ''.obs;
  final feeDueDay = ''.obs;
  final salaryDay = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    _clear();
    final res = await _loader();
    if (res.success && res.data != null) {
      _fill(res.data!);
    } else {
      error.value = res.error ?? 'Could not load school settings.';
    }
    loading.value = false;
  }

  void _clear() {
    name.value = '';
    logoUrl.value = '';
    uniformColor.value = '';
    feeDueDay.value = '';
    salaryDay.value = '';
  }

  void _fill(SchoolProfile p) {
    name.value = p.name;
    logoUrl.value = p.logoUrl ?? '';
    uniformColor.value = p.uniformColor ?? '';
    feeDueDay.value = p.feeDueDay?.toString() ?? '';
    salaryDay.value = p.salaryDay?.toString() ?? '';
  }

  int? _validDay(RxString field) {
    final raw = field.value.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    return (v != null && v >= 1 && v <= 31) ? v : -1; // -1 = invalid sentinel
  }

  Future<void> save() async {
    if (name.value.trim().isEmpty) {
      Get.snackbar(
        'Name required',
        'School name cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final day = _validDay(feeDueDay);
    if (day == -1) {
      Get.snackbar(
        'Invalid fee day',
        'Enter a day between 1 and 31.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final salary = _validDay(salaryDay);
    if (salary == -1) {
      Get.snackbar(
        'Invalid salary day',
        'Enter a day between 1 and 31.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    saving.value = true;
    final res = await _repo.saveSchoolProfile(
      name: name.value.trim(),
      logoUrl: logoUrl.value.trim().isEmpty ? null : logoUrl.value.trim(),
      uniformColor: uniformColor.value.trim().isEmpty
          ? null
          : uniformColor.value.trim(),
      feeDueDay: day,
      salaryDay: salary,
    );
    saving.value = false;
    if (res.success) {
      if (res.data != null) _fill(res.data!);
      Get.snackbar(
        'Settings saved',
        'Your school settings were updated.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Could not save',
        res.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
