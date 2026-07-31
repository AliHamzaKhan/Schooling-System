import 'package:get/get.dart';

import '../../../../../widgets/leave_review.dart';
import '../../../data/headmaster_repository.dart';

/// Headmaster leave review — every request in the school, with approve/reject.
class LeaveReviewController extends GetxController {
  final HeadmasterRepository _repo;
  LeaveReviewController({HeadmasterRepository? repo})
      : _repo = repo ?? Get.find<HeadmasterRepository>();

  final loading = true.obs;
  final error = RxnString();
  final acting = false.obs;
  final items = <LeaveReviewItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadLeaveReview();
    if (res.success && res.data != null) {
      items.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load leave requests.';
    }
    loading.value = false;
  }

  List<LeaveReviewItem> get pending =>
      items.where((i) => i.isPending).toList();
  List<LeaveReviewItem> get reviewed =>
      items.where((i) => !i.isPending).toList();

  /// Every loaded leave for a given student, newest-loaded first — the review
  /// list already carries the whole school's history, so this needs no extra
  /// fetch.
  List<LeaveReviewItem> historyFor(String studentId) =>
      items.where((i) => i.studentId == studentId).toList();

  Future<void> review(String leaveId, bool approve) async {
    if (acting.value) return;
    acting.value = true;
    final res =
        await _repo.reviewLeave(leaveId: leaveId, approve: approve);
    acting.value = false;
    if (res.success) {
      await load();
      Get.snackbar('Done', approve ? 'Leave approved.' : 'Leave rejected.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', res.error ?? 'Could not update the request.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
