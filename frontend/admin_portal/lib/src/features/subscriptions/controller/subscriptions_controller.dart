import 'package:get/get.dart';

import '../models/plans_repository.dart';
import '../models/subscription_models.dart';

/// Drives the Subscription Plans screen: lists the live, editable plans and
/// creates / updates / archives them via the backend.
class SubscriptionsController extends GetxController {
  SubscriptionsController({PlansRepository? repo})
      : _repo = repo ?? PlansRepository();

  final PlansRepository _repo;

  final loading = true.obs;
  final error = RxnString();
  final plans = <SubscriptionPlanModel>[].obs;
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

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

  /// Creates a plan (create form) or updates [existing] when provided. Returns
  /// true on success so the caller can dismiss its form.
  Future<bool> savePlan({
    SubscriptionPlanModel? existing,
    required String name,
    required double price,
    required BillingPeriod billingPeriod,
    required List<String> modules,
    String? description,
    int? maxStudents,
    int? storageQuotaMb,
  }) async {
    saving.value = true;
    final res = existing == null
        ? await _repo.create(
            name: name,
            price: price,
            billingPeriod: billingPeriod,
            description: description,
            maxStudents: maxStudents,
            storageQuotaMb: storageQuotaMb,
            modules: modules,
          )
        : await _repo.update(
            existing.id,
            name: name,
            price: price,
            billingPeriod: billingPeriod,
            description: description,
            maxStudents: maxStudents,
            storageQuotaMb: storageQuotaMb,
            modules: modules,
          );
    saving.value = false;
    if (res.success) {
      await fetch();
      Get.snackbar('Saved', '$name saved.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    }
    Get.snackbar('Error', res.error ?? 'Could not save the plan.',
        snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  Future<void> archivePlan(SubscriptionPlanModel plan) async {
    final res = await _repo.archive(plan.id);
    if (res.success) {
      await fetch();
      Get.snackbar('Archived', '${plan.name} archived.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', res.error ?? 'Could not archive the plan.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
