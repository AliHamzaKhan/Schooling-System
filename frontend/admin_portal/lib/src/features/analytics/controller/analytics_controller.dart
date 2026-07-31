import 'package:get/get.dart';

import '../../../data/models/admin_metrics.dart';
import '../models/analytics_repository.dart';

/// Drives the System Metrics screen (live `/admin/metrics`).
class AnalyticsController extends GetxController {
  AnalyticsController({AnalyticsRepository? repo})
      : _repo = repo ?? AnalyticsRepository();

  final AnalyticsRepository _repo;

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<MetricsReport>();

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
      data.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load metrics.';
    }
    loading.value = false;
  }
}
