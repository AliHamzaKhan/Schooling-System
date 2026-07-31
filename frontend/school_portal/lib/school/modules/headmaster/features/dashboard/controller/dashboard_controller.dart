import 'package:get/get.dart';

import '../../../data/headmaster_repository.dart';
import '../models/dashboard_data.dart';
import '../models/subscription_status.dart';

/// Drives the Headmaster Dashboard.
class HeadmasterDashboardController extends GetxController {
  final HeadmasterRepository _repo;
  HeadmasterDashboardController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<DashboardData>();

  /// Subscription status for the expiry alert (loaded alongside the dashboard,
  /// but never blocks it — a status failure just hides the alert).
  final subscription = Rxn<SubscriptionStatus>();

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
    await _loadSubscription();
    loading.value = false;
  }

  Future<void> _loadSubscription() async {
    final res = await _repo.loadSubscriptionStatus();
    subscription.value = res.success ? res.data : null;
  }

  void approve(String id) =>
      Get.snackbar('Approved', 'Approval $id sent.',
          snackPosition: SnackPosition.BOTTOM);

  void reject(String id) =>
      Get.snackbar('Rejected', 'Approval $id rejected.',
          snackPosition: SnackPosition.BOTTOM);
}
