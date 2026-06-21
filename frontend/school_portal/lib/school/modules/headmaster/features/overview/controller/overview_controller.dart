import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/overview_data.dart';

class OverviewController extends GetxController {
  final HeadmasterRepository _repo;
  OverviewController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<OverviewData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadOverview();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load overview.';
    }
    loading.value = false;
  }
}
