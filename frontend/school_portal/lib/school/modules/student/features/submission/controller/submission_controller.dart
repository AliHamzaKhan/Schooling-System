import 'package:file_picker/file_picker.dart';
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
  final fileSize = Rxn<int>();
  final submitting = false.obs;
  final error = RxnString();

  // Bytes of the picked file, uploaded to storage on submit.
  List<int>? _pickedBytes;

  @override
  void onInit() {
    super.onInit();
    // Preferred path: the assignment object is passed straight from the list, so
    // the detail is the real (live) assignment. A bare id string is still
    // accepted as a fallback.
    final arg = Get.arguments;
    if (arg is StudentAssignment) {
      assignment.value = arg;
      loading.value = false;
    } else {
      load(arg is String ? arg : '');
    }
  }

  /// Opens the OS / browser file picker (PDF only) and records the chosen file.
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    filename.value = file.name;
    fileSize.value = file.size;
    _pickedBytes = file.bytes;
  }

  void clearFile() {
    filename.value = null;
    fileSize.value = null;
    _pickedBytes = null;
  }

  Future<void> submit() async {
    final id = assignment.value?.id ?? '';
    if (id.isEmpty) {
      error.value = "This assignment can't be submitted.";
      return;
    }
    submitting.value = true;
    error.value = null;

    // Upload the picked file first (if any) to get its stored URL.
    String? attachmentUrl;
    final bytes = _pickedBytes;
    final name = filename.value;
    if (bytes != null && name != null) {
      final upload = await _repo.uploadFile(bytes: bytes, filename: name);
      if (!upload.success || (upload.data ?? '').isEmpty) {
        submitting.value = false;
        error.value = upload.error ?? 'File upload failed. Please try again.';
        return;
      }
      attachmentUrl = upload.data;
    }

    final res = await _repo.submitAssignment(
      id,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      attachmentUrl: attachmentUrl,
    );
    submitting.value = false;
    if (res.success) {
      Get.back<bool>(result: true);
      Get.snackbar('Turned in', 'Your assignment was submitted.',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      error.value = res.error ?? 'Could not submit. Please try again.';
    }
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
