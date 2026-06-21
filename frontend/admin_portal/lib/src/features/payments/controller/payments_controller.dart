import 'package:get/get.dart';

import '../models/payments_data.dart';
import '../models/payments_repository.dart';

/// Drives the Payments & Billing dashboard.
class PaymentsController extends GetxController {
  final PaymentsRepository _repo;
  PaymentsController({PaymentsRepository? repo})
      : _repo = repo ?? PaymentsRepository();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<PaymentsData>();
  final range = 'This Month'.obs;

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
      error.value = res.error ?? 'Could not load payments.';
    }
    loading.value = false;
  }
}
