import 'package:get/get.dart';
import 'package:shared/shared.dart';

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

  /// The signed-in headmaster's display name, for the identity card. The
  /// payload's `greeting` is a greeting, not a name, so it is not reused here.
  String get headmasterName {
    final full = Get.find<AuthService>().fullName?.trim() ?? '';
    return full.isEmpty ? 'Headmaster' : full;
  }

  /// The school's display name, shown in the dashboard greeting. Loaded
  /// best-effort alongside the dashboard; empty until it resolves.
  final schoolName = ''.obs;

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
    await _loadSchoolName();
    loading.value = false;
  }

  Future<void> _loadSubscription() async {
    final res = await _repo.loadSubscriptionStatus();
    subscription.value = res.success ? res.data : null;
  }

  Future<void> _loadSchoolName() async {
    final res = await _repo.loadSchoolProfile();
    if (res.success && res.data != null) schoolName.value = res.data!.name;
  }

  void approve(String id) =>
      Get.snackbar('Approved', 'Approval $id sent.',
          snackPosition: SnackPosition.BOTTOM);

  void reject(String id) =>
      Get.snackbar('Rejected', 'Approval $id rejected.',
          snackPosition: SnackPosition.BOTTOM);
}
