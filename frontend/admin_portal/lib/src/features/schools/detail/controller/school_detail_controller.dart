import 'package:get/get.dart';

import '../../../../data/admin_api_service.dart';
import '../../../subscriptions/models/subscription_models.dart';
import '../../models/school.dart';
import '../models/school_detail_models.dart';

/// Drives the School Detail screen: loads the school's active-user stats, its
/// current subscription (for plan + expiry), and its payment ledger. The
/// [school] itself arrives via `Get.arguments`; [refresh] re-pulls everything
/// (e.g. after the plan is changed from the subscription sheet).
class SchoolDetailController extends GetxController {
  final AdminApiService _api;
  School school;

  SchoolDetailController({required this.school, AdminApiService? api})
      : _api = api ?? AdminApiService();

  final loading = true.obs;
  final error = RxnString();

  final stats = Rxn<SchoolStats>();
  final subscription = Rxn<SchoolSubscriptionModel>();
  final payments = <SchoolPayment>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final statsRes = await _api.fetchSchoolStats(school.id);
    if (statsRes.success && statsRes.data != null) {
      stats.value = statsRes.data;
    } else {
      error.value = statsRes.error ?? 'Could not load school details.';
    }

    final subsRes = await _api.fetchSubscriptions();
    if (subsRes.success && subsRes.data != null) {
      subscription.value = _pickSubscription(subsRes.data!);
    }

    final payRes = await _api.fetchSchoolPayments(school.id);
    if (payRes.success && payRes.data != null) {
      payments.assignAll(payRes.data!);
    }

    loading.value = false;
  }

  /// The subscription to headline: prefer an active one, otherwise the one with
  /// the latest end date. Filtered to this school.
  SchoolSubscriptionModel? _pickSubscription(List<SchoolSubscriptionModel> all) {
    final mine = all.where((s) => s.schoolId == school.id).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) {
      final aActive = a.status == SubscriptionStatus.active ? 1 : 0;
      final bActive = b.status == SubscriptionStatus.active ? 1 : 0;
      if (aActive != bActive) return bActive - aActive;
      return b.endDate.compareTo(a.endDate);
    });
    return mine.first;
  }

  /// Days until the current subscription expires (negative if already expired),
  /// or null when there is no subscription.
  int? get daysRemaining {
    final sub = subscription.value;
    if (sub == null) return null;
    return sub.endDate.difference(DateTime.now()).inDays;
  }
}
