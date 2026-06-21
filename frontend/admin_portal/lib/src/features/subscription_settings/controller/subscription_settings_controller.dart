import 'package:get/get.dart';

import '../models/subscription_settings_models.dart';

/// Drives Subscription Settings: loads the current plan + usage, and toggles
/// billing cycle / auto-renew.
class SubscriptionSettingsController extends GetxController {
  final SubscriptionSettingsRepository _repo;
  SubscriptionSettingsController({SubscriptionSettingsRepository? repo})
      : _repo = repo ?? SubscriptionSettingsRepository();

  final loading = true.obs;
  final settings = Rxn<SubscriptionSettings>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    final res = await _repo.load();
    if (res.success && res.data != null) settings.value = res.data;
    loading.value = false;
  }

  void setCycle(String cycle) {
    final s = settings.value;
    if (s != null) settings.value = s.copyWith(billingCycle: cycle);
  }

  void setAutoRenew(bool value) {
    final s = settings.value;
    if (s != null) settings.value = s.copyWith(autoRenew: value);
  }
}
