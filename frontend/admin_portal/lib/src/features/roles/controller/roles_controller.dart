import 'package:get/get.dart';

import '../models/role_models.dart';

/// Drives Role Management: loads roles, supports activating/deactivating, and
/// exposes them grouped by hierarchy level for the visualization.
class RolesController extends GetxController {
  final RolesRepository _repo;
  RolesController({RolesRepository? repo}) : _repo = repo ?? RolesRepository();

  final loading = true.obs;
  final roles = <ManagedRole>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.load();
    if (res.success && res.data != null) roles.assignAll(res.data!);
    loading.value = false;
  }

  /// Roles bucketed by [ManagedRole.level], ordered top-down — feeds the
  /// hierarchical permission visualization.
  List<MapEntry<int, List<ManagedRole>>> get byLevel {
    final map = <int, List<ManagedRole>>{};
    for (final r in roles) {
      map.putIfAbsent(r.level, () => []).add(r);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  void toggleActive(String id, bool value) {
    final i = roles.indexWhere((r) => r.id == id);
    if (i != -1) roles[i] = roles[i].copyWith(active: value);
  }
}
