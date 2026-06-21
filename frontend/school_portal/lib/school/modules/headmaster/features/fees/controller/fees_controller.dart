import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/fees_data.dart';

/// Drives the Fee Management dashboard.
class FeesController extends GetxController {
  final HeadmasterRepository _repo;
  FeesController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<FeesData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadFees();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load fees.';
    }
    loading.value = false;
  }
}
