import 'package:get/get.dart';

import '../../../data/models/dashboard_stats.dart';
import '../../../data/repositories/dashboard_repository.dart';

/// Drives the admin home dashboard: loads KPIs + the alerts feed.
class DashboardController extends GetxController {
  final DashboardRepository _repo;
  DashboardController({DashboardRepository? repo})
      : _repo = repo ?? DashboardRepository();

  final loading = true.obs;
  final error = RxnString();
  final metrics = <StatMetric>[].obs;
  final alerts = <AdminAlert>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.load();
    if (res.success && res.data != null) {
      metrics.assignAll(res.data!.metrics);
      alerts.assignAll(res.data!.alerts);
    } else {
      error.value = res.error ?? 'Could not load the dashboard.';
    }
    loading.value = false;
  }
}
