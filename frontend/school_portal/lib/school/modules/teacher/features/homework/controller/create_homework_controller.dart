import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../../quiz/models/quiz_models.dart' show IdLabel;

/// Drives the Create Homework form.
///
/// Section and subject come from the school's real academic structure (with
/// their UUIDs), because the backend assigns homework to a `section_id` +
/// `subject_id` — not a display label.
class CreateHomeworkController extends GetxController {
  final TeacherRepository _repo;
  CreateHomeworkController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final dueCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '100');

  final loadingOptions = true.obs;
  final sections = <IdLabel>[].obs;
  final subjects = <IdLabel>[].obs;
  final selectedSection = RxnString();
  final selectedSubject = RxnString();

  final dueDate = Rxn<DateTime>();
  final submitting = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    loadingOptions.value = true;
    final sec = await _repo.loadSectionOptions();
    final sub = await _repo.loadSubjectOptions();
    if (sec.success) sections.assignAll(sec.data ?? const []);
    if (sub.success) subjects.assignAll(sub.data ?? const []);
    loadingOptions.value = false;
  }

  void selectSection(String? v) => selectedSection.value = v;
  void selectSubject(String? v) => selectedSubject.value = v;

  /// Opens a calendar picker for the due date and reflects the choice in the
  /// read-only [dueCtrl] text field.
  Future<void> pickDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate.value ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    dueDate.value = picked;
    dueCtrl.text = _formatDate(picked);
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  /// Backend wants an ISO calendar date (YYYY-MM-DD) for `due_date`.
  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> submit() async {
    error.value = null;
    if (titleCtrl.text.trim().length < 2) {
      error.value = 'A task title is required.';
      return;
    }
    if (selectedSection.value == null) {
      error.value = 'Pick a section to assign to.';
      return;
    }
    if (selectedSubject.value == null) {
      error.value = 'Pick a subject.';
      return;
    }
    if (dueDate.value == null) {
      error.value = 'Pick a due date.';
      return;
    }

    submitting.value = true;
    final res = await _repo.createHomework(
      sectionId: selectedSection.value!,
      subjectId: selectedSubject.value!,
      title: titleCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      dueDate: _isoDate(dueDate.value!),
      maxMarks: double.tryParse(pointsCtrl.text.trim()),
    );
    submitting.value = false;

    if (!res.success) {
      error.value = res.error ?? 'Could not post the homework.';
      return;
    }
    Get.back<bool>(result: true);
    Get.snackbar('Posted', '“${titleCtrl.text.trim()}” assigned.',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    dueCtrl.dispose();
    pointsCtrl.dispose();
    super.onClose();
  }
}
