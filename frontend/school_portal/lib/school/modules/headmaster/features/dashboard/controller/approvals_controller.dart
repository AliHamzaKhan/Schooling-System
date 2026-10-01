import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/headmaster_repository.dart';
import '../models/dashboard_data.dart';

typedef ApprovalsLoader = Future<ApiResponse<DashboardData>> Function();

/// Reloads the approvals list from the canonical dashboard source so this
/// route remains useful after a refresh or direct URL entry.
class ApprovalsController extends GetxController {
  final ApprovalsLoader _loader;
  final HeadmasterRepository? _repository;

  ApprovalsController({
    HeadmasterRepository? repository,
    ApprovalsLoader? loader,
  }) : _repository = repository,
       _loader =
           loader ??
           (repository ?? Get.find<HeadmasterRepository>()).loadDashboard;

  HeadmasterRepository get _reviewRepo =>
      _repository ?? Get.find<HeadmasterRepository>();

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

  /// Approves or rejects a pending leave request, then reloads the queue.
  Future<void> approve(String id) => _review(id, true);

  Future<void> reject(String id) => _review(id, false);

  Future<void> _review(String id, bool approve) async {
    final res = await _reviewRepo.reviewLeave(leaveId: id, approve: approve);
    Get.snackbar(
      res.success ? (approve ? 'Approved' : 'Rejected') : 'Not saved',
      res.success
          ? 'The leave request was ${approve ? 'approved' : 'rejected'}.'
          : (res.error ?? 'Please try again.'),
      snackPosition: SnackPosition.BOTTOM,
    );
    if (res.success) await load();
  }
}
