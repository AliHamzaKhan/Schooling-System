import 'package:get/get.dart';

import '../../../../../widgets/leave_review.dart';
import '../../../data/guardian_repository.dart';
import '../../../shared/controller/guardian_session_controller.dart';
import '../../../shared/models/child.dart';

/// Lets a guardian submit a leave application for one of their children and
/// track its status. Routed to that child's class teacher + headmaster.
class GuardianLeaveController extends GetxController {
  final GuardianRepository _repo;
  final GuardianSessionController _session;
  GuardianLeaveController({
    GuardianRepository? repo,
    GuardianSessionController? session,
  })  : _repo = repo ?? Get.find<GuardianRepository>(),
        _session = session ?? Get.find<GuardianSessionController>();

  static const leaveTypes = ['sick', 'casual', 'family', 'other'];

  final loading = true.obs;
  final error = RxnString();
  final items = <LeaveReviewItem>[].obs;

  // Form state.
  final childId = RxnString();
  final leaveType = 'sick'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  /// Reason text. The `TextEditingController` behind it belongs to the submit
  /// sheet's State, so it lives and dies with that sheet.
  final reason = ''.obs;
  final submitting = false.obs;
  final formError = RxnString();

  List<Child> get children => _session.children;

  @override
  void onInit() {
    super.onInit();
    childId.value = _session.selectedId.value;
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadMyLeave();
    if (res.success && res.data != null) {
      items.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load leave applications.';
    }
    loading.value = false;
  }

  void resetForm() {
    childId.value = _session.selectedId.value ??
        (children.isNotEmpty ? children.first.id : null);
    leaveType.value = 'sick';
    startDate.value = null;
    endDate.value = null;
    reason.value = '';
    formError.value = null;
  }

  static String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<bool> submit() async {
    formError.value = null;
    final child = childId.value;
    final start = startDate.value;
    final end = endDate.value;
    if (child == null) {
      formError.value = 'Select which child this leave is for.';
      return false;
    }
    if (start == null || end == null) {
      formError.value = 'Pick both a start and end date.';
      return false;
    }
    if (end.isBefore(start)) {
      formError.value = 'End date cannot be before the start date.';
      return false;
    }
    submitting.value = true;
    final res = await _repo.submitLeave(
      studentId: child,
      leaveType: leaveType.value,
      startDate: fmt(start),
      endDate: fmt(end),
      reason: reason.value.trim().isEmpty ? null : reason.value.trim(),
    );
    submitting.value = false;
    if (!res.success) {
      formError.value = res.error ?? 'Could not submit. Please try again.';
      return false;
    }
    await load();
    return true;
  }
}
