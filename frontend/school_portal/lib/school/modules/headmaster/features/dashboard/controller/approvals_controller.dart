import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/dashboard_data.dart';

typedef ApprovalsLoader = Future<ApiResponse<DashboardData>> Function();

/// Reloads the approvals list from the canonical dashboard source so this
/// route remains useful after a refresh or direct URL entry.
class ApprovalsController extends GetxController {
  final ApprovalsLoader _loader;

  ApprovalsController({
    HeadmasterRepository? repository,
    ApprovalsLoader? loader,
  }) : _loader =
           loader ??
           (repository ?? Get.find<HeadmasterRepository>()).loadDashboard;

  final loading = true.obs;
  final error = RxnString();
  final approvals = <PendingApproval>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    approvals.clear();
    final result = await _loader();
    if (result.success && result.data != null) {
      approvals.assignAll(result.data!.approvals);
    } else {
      error.value = result.error ?? 'Could not load pending approvals.';
    }
    loading.value = false;
  }

  void approve(String id) => Get.snackbar(
    'Approved',
    'Approval $id sent.',
    snackPosition: SnackPosition.BOTTOM,
  );

  void reject(String id) => Get.snackbar(
    'Rejected',
    'Approval $id rejected.',
    snackPosition: SnackPosition.BOTTOM,
  );
}
