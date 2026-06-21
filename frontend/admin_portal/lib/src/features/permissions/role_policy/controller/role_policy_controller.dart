import 'package:get/get.dart';

import '../../models/permission_models.dart';

/// Drives the Role-Based Access Control screen: role selection and per-group
/// permission toggles with dirty-state tracking for Save/Discard.
class RolePolicyController extends GetxController {
  final roles = PermissionsData.roles;
  final selectedRole = PermissionsData.roles.first.obs;
  final groups = <PermissionGroup>[].obs;
  final dirty = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPolicy();
  }

  void _loadPolicy() {
    // Per-role policies would come from the API; mock uses one default set.
    groups.assignAll(PermissionsData.defaultPolicy());
    dirty.value = false;
  }

  void selectRole(PermissionRole role) {
    if (role.id == selectedRole.value.id) return;
    selectedRole.value = role;
    _loadPolicy();
  }

  void toggle(int groupIndex, String itemKey, bool value) {
    final group = groups[groupIndex];
    final items = group.items
        .map((it) => it.key == itemKey ? it.copyWith(enabled: value) : it)
        .toList();
    groups[groupIndex] = group.copyWith(items: items);
    dirty.value = true;
  }

  void discard() => _loadPolicy();

  Future<void> save() async {
    // TODO: POST policy to the API.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    dirty.value = false;
  }
}
