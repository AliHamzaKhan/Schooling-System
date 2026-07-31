import 'package:get/get.dart';

import '../../../data/models/admin_metrics.dart';
import '../models/payments_repository.dart';

/// Drives the Payments & Billing screen (live `/admin/billing`).
class PaymentsController extends GetxController {
  PaymentsController({PaymentsRepository? repo})
      : _repo = repo ?? PaymentsRepository();

  final PaymentsRepository _repo;

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<BillingReport>();

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
      error.value = res.error ?? 'Could not load billing.';
    }
    loading.value = false;
  }
}
