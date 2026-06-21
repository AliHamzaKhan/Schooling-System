import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/dashboard_data.dart';

/// Drives the Headmaster Dashboard.
class DashboardController extends GetxController {
  final HeadmasterRepository _repo;
  DashboardController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<DashboardData>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadDashboard();
    if (res.success && res.data != null) {
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load dashboard.';
    }
    loading.value = false;
  }

  void approve(String id) =>
      Get.snackbar('Approved', 'Approval $id sent.',
          snackPosition: SnackPosition.BOTTOM);

  void reject(String id) =>
      Get.snackbar('Rejected', 'Approval $id rejected.',
          snackPosition: SnackPosition.BOTTOM);
}
