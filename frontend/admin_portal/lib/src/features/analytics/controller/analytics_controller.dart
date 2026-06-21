import 'package:get/get.dart';

import '../models/analytics_data.dart';
import '../models/analytics_repository.dart';

/// Drives the Analytics Overview screen.
class AnalyticsController extends GetxController {
  final AnalyticsRepository _repo;
  AnalyticsController({AnalyticsRepository? repo})
      : _repo = repo ?? AnalyticsRepository();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<AnalyticsData>();

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
      error.value = res.error ?? 'Could not load analytics.';
    }
    loading.value = false;
  }
}
