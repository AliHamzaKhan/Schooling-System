import 'package:get/get.dart';

import '../models/feature_models.dart';

/// Drives the Feature Access Control Panel: loads feature modules and toggles
/// individual flags. Exposes an enabled-count summary.
class FeatureAccessController extends GetxController {
  final FeatureAccessRepository _repo;
  FeatureAccessController({FeatureAccessRepository? repo})
      : _repo = repo ?? FeatureAccessRepository();

  final loading = true.obs;
  final modules = <FeatureModule>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.load();
    if (res.success && res.data != null) modules.assignAll(res.data!);
    loading.value = false;
  }

  int get enabledCount => modules
      .expand((m) => m.features)
      .where((f) => f.enabled)
      .length;

  int get totalCount => modules.expand((m) => m.features).length;

  void toggle(int moduleIndex, String key, bool value) {
    final module = modules[moduleIndex];
    final features = module.features
        .map((f) => f.key == key ? f.copyWith(enabled: value) : f)
        .toList();
    modules[moduleIndex] = module.copyWith(features: features);
  }
}
