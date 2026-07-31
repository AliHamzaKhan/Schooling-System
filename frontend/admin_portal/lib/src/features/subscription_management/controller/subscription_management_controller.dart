import 'package:get/get.dart';

import '../../subscriptions/models/subscription_models.dart';
import '../models/subscription_management_repository.dart';

/// Drives the Subscription Management screen: the All / Active / Pending /
/// History tabs and the per-row renew / cancel actions.
class SubscriptionManagementController extends GetxController {
  SubscriptionManagementController({SubscriptionManagementRepository? repo})
      : _repo = repo ?? SubscriptionManagementRepository();

  final SubscriptionManagementRepository _repo;

  /// Tab labels; `_filters[i]` is the backend `status_filter` for tab `i`.
  static const tabs = ['All', 'Active', 'Pending', 'History'];
  static const _filters = ['all', 'active', 'pending', 'history'];

  final loading = true.obs;
  final error = RxnString();
  final subscriptions = <SchoolSubscriptionModel>[].obs;
  final tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void selectTab(int index) {
    if (tabIndex.value == index) return;
    tabIndex.value = index;
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.fetch(_filters[tabIndex.value]);
    if (res.success && res.data != null) {
      subscriptions.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load subscriptions.';
    }
    loading.value = false;
  }

  Future<void> renew(SchoolSubscriptionModel sub) async {
    final res = await _repo.renew(sub.id);
    if (res.success) {
      await fetch();
      Get.snackbar('Renewed', '${sub.schoolName ?? 'Subscription'} renewed.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', res.error ?? 'Could not renew.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> cancel(SchoolSubscriptionModel sub) async {
    final res = await _repo.cancel(sub.id);
    if (res.success) {
      await fetch();
      Get.snackbar('Cancelled', '${sub.schoolName ?? 'Subscription'} cancelled.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', res.error ?? 'Could not cancel.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
