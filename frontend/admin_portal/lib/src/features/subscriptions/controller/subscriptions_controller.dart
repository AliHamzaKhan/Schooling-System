import 'package:get/get.dart';

import '../models/subscription_plan.dart';
import '../models/subscriptions_repository.dart';

enum BillingCycle { monthly, yearly }

/// Drives the Subscription Management screen: the billing-cycle toggle and the
/// list of pricing tiers.
class SubscriptionsController extends GetxController {
  final SubscriptionsRepository _repo;
  SubscriptionsController({SubscriptionsRepository? repo})
      : _repo = repo ?? SubscriptionsRepository();

  final loading = true.obs;
  final error = RxnString();
  final plans = <SubscriptionPlan>[].obs;
  final cycle = BillingCycle.monthly.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void setCycle(BillingCycle c) => cycle.value = c;

  String priceFor(SubscriptionPlan p) =>
      cycle.value == BillingCycle.monthly ? p.monthlyPrice : p.yearlyPrice;

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.fetch();
    if (res.success && res.data != null) {
      plans.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load plans.';
    }
    loading.value = false;
  }
}
