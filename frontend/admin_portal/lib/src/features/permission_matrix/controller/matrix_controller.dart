import 'package:get/get.dart';

import '../models/matrix_models.dart';

/// Drives the Permission Assignment matrix: holds the grant set as observable
/// "perm:role" keys, supports per-cell toggles, whole-column (role) and
/// whole-row (permission) bulk toggles, and dirty tracking for Save/Discard.
class MatrixController extends GetxController {
  final MatrixRepository _repo;
  MatrixController({MatrixRepository? repo})
      : _repo = repo ?? MatrixRepository();

  final loading = true.obs;
  final matrix = Rxn<PermissionMatrix>();
  final grants = <String>{}.obs;
  final dirty = false.obs;

  /// Optional role to pre-highlight (passed from Role Management).
  String? focusRoleId;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String) focusRoleId = arg;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.load();
    if (res.success && res.data != null) {
      matrix.value = res.data;
      grants.assignAll(res.data!.grants);
    }
    dirty.value = false;
    loading.value = false;
  }

  String _cell(String perm, String role) => '$perm:$role';

  bool isGranted(String perm, String role) =>
      grants.contains(_cell(perm, role));

  void toggle(String perm, String role) {
    final key = _cell(perm, role);
    if (grants.contains(key)) {
      grants.remove(key);
    } else {
      grants.add(key);
    }
    dirty.value = true;
  }

  /// Enable/disable every permission for a role (column action).
  void setRoleAll(String role, bool value) {
    final m = matrix.value;
    if (m == null) return;
    for (final cat in m.categories) {
      for (final p in cat.permissions) {
        final key = _cell(p.key, role);
        value ? grants.add(key) : grants.remove(key);
      }
    }
    dirty.value = true;
  }

  void discard() {
    final m = matrix.value;
    if (m != null) grants.assignAll(m.grants);
    dirty.value = false;
  }

  Future<void> save() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Rebase the baseline so Discard returns to the saved state.
    final m = matrix.value;
    if (m != null) {
      matrix.value = PermissionMatrix(
        roles: m.roles,
        categories: m.categories,
        grants: grants.toSet(),
      );
    }
    dirty.value = false;
  }
}
