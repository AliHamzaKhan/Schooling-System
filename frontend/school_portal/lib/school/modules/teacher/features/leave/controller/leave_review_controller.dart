import 'package:get/get.dart';

import '../../../../../widgets/leave_review.dart';
import '../../../data/teacher_repository.dart';

/// Class-teacher leave review — requests for the teacher's own section students.
class TeacherLeaveReviewController extends GetxController {
  final TeacherRepository _repo;
  TeacherLeaveReviewController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

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

  List<LeaveReviewItem> get pending => items.where((i) => i.isPending).toList();
  List<LeaveReviewItem> get reviewed => items.where((i) => !i.isPending).toList();

  Future<void> review(String leaveId, bool approve) async {
    if (acting.value) return;
    acting.value = true;
    final res = await _repo.reviewLeave(leaveId: leaveId, approve: approve);
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
