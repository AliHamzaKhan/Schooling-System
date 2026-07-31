import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/leave_models.dart';

/// Lists the student's own leave applications and drives the submit form.
class LeaveController extends GetxController {
  final StudentRepository _repo;
  LeaveController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  static const leaveTypes = ['sick', 'casual', 'family', 'other'];

  final loading = true.obs;
  final error = RxnString();
  final items = <LeaveRequest>[].obs;

  // ── Submit form state ──
  final leaveType = 'sick'.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final reasonCtrl = TextEditingController();
  final submitting = false.obs;
  final formError = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    reasonCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadMyLeave();
    if (res.success && res.data != null) {
      items.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load your leave applications.';
    }
    loading.value = false;
  }

  void resetForm() {
    leaveType.value = 'sick';
    startDate.value = null;
    endDate.value = null;
    reasonCtrl.clear();
    formError.value = null;
  }

  static String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Validates and submits. Returns true when the application was created.
  Future<bool> submit() async {
    formError.value = null;
    final start = startDate.value;
    final end = endDate.value;
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
      leaveType: leaveType.value,
      startDate: fmt(start),
      endDate: fmt(end),
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
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
