import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../../assignments/models/assignment.dart';

class SubmissionController extends GetxController {
  final StudentRepository _repo;
  SubmissionController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final assignment = Rxn<StudentAssignment>();
  final notesCtrl = TextEditingController();
  final filename = RxnString();
  final submitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments is String ? Get.arguments as String : 'A-IR';
    load(id);
  }

  /// Stub — in a real app this opens a file picker. We just stash a fake name
  /// so the UI can render an "Uploaded" state.
  void pickFile() {
    filename.value = filename.value == null ? 'My_Essay.pdf' : null;
  }

  Future<void> submit() async {
    submitting.value = true;
    await _repo.submitAssignment(
      assignment.value?.id ?? '',
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      filename: filename.value,
    );
    submitting.value = false;
    Get.back<bool>(result: true);
    Get.snackbar('Turned in', 'Your assignment was submitted.',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> load(String id) async {
    loading.value = true;
    final res = await _repo.loadAssignment(id);
    if (res.success) assignment.value = res.data;
    loading.value = false;
  }

  @override
  void onClose() {
    notesCtrl.dispose();
    super.onClose();
  }
}
