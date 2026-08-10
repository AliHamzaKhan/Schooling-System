import 'package:get/get.dart';

import '../../../schools/models/school.dart';
import '../../models/module_models.dart';
import '../../models/school_modules_repository.dart';

/// Drives the per-school module editor: loads the school's plan ∩ toggle view,
/// lets the admin flip in-plan modules on/off, and saves the changed toggles.
class SchoolModulesController extends GetxController {
  final SchoolModulesRepository _repo;
  final School school;

  SchoolModulesController({required this.school, SchoolModulesRepository? repo})
      : _repo = repo ?? SchoolModulesRepository();

  final loading = true.obs;
  final saving = false.obs;
  final error = RxnString();
  final planCode = RxnString();

  /// Current module statuses, keyed by module value for quick lookup/edits.
  final statuses = <String, ModuleStatus>{}.obs;

  /// Server-side toggle values at load time — used to compute what actually
  /// changed so we only send diffs.
  final Map<String, bool> _original = {};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.load(school.id);
    if (!res.success || res.data == null) {
      error.value = res.error ?? 'Could not load module permissions.';
      loading.value = false;
      return;
    }
    _apply(res.data!);
    loading.value = false;
  }

  void _apply(SchoolModulesView view) {
    planCode.value = view.planCode;
    final map = <String, ModuleStatus>{};
    _original.clear();
    for (final m in view.modules) {
      map[m.module] = m;
      _original[m.module] = m.toggleEnabled;
    }
    statuses.assignAll(map);
  }

  int get activeCount => statuses.values.where((m) => m.effective).length;
  int get totalCount => statuses.length;

  /// Whether any in-plan module's toggle differs from what the server returned.
  bool get hasChanges =>
      statuses.values.any((m) => _original[m.module] != m.toggleEnabled);

  /// Flip a module's toggle locally. In-plan modules only — modules the plan
  /// doesn't include cannot be enabled here (change the plan first).
  void toggle(String module, bool value) {
    final current = statuses[module];
    if (current == null || !current.inPlan) return;
    statuses[module] = current.copyWith(toggleEnabled: value);
  }

  Future<void> save() async {
    if (!hasChanges || saving.value) return;
    saving.value = true;
    final toggles = statuses.values
        .where((m) => _original[m.module] != m.toggleEnabled)
        .map((m) => ModuleToggle(module: m.module, enabled: m.toggleEnabled))
        .toList();

    final res = await _repo.save(school.id, toggles);
    saving.value = false;
    if (!res.success || res.data == null) {
      Get.snackbar('Save failed', res.error ?? 'Could not update modules.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _apply(res.data!);
    Get.snackbar('Saved', 'Module permissions updated for ${school.name}.',
        snackPosition: SnackPosition.BOTTOM);
  }
}
