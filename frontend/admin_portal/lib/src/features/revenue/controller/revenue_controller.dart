import 'package:get/get.dart';

import '../../../data/admin_api_service.dart';
import '../../../data/models/admin_metrics.dart';

/// Drives the Revenue report screen: monthly earnings from `/admin/revenue`.
class RevenueController extends GetxController {
  RevenueController({AdminApiService? api}) : _api = api ?? AdminApiService();

  final AdminApiService _api;

  final loading = true.obs;
  final error = RxnString();
  final report = Rxn<RevenueReport>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _api.fetchRevenue(months: 12);
    if (res.success && res.data != null) {
      report.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load revenue.';
    }
    loading.value = false;
  }
}
