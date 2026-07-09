import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';

/// Drives the Create Homework form.
class CreateHomeworkController extends GetxController {
  final TeacherRepository _repo;
  CreateHomeworkController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  static const classes = ['Algebra 101', 'Calculus II', 'Geometry'];

  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final dueCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '100');

  final selectedClass = RxnString();
  final dueDate = Rxn<DateTime>();
  final submitting = false.obs;
  final error = RxnString();

  void selectClass(String? v) => selectedClass.value = v;

  /// Opens a calendar picker for the due date and reflects the choice in the
  /// read-only [dueCtrl] text field (mm/dd/yyyy).
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

  Future<void> submit() async {
    error.value = null;
    if (titleCtrl.text.trim().isEmpty) {
      error.value = 'A task title is required.';
      return;
    }
    if (selectedClass.value == null) {
      error.value = 'Pick a class to assign to.';
      return;
    }
    submitting.value = true;
    await _repo.createHomework({
      'title': titleCtrl.text.trim(),
      'description': descriptionCtrl.text.trim(),
      'class': selectedClass.value,
      'due': dueDate.value?.toIso8601String() ?? dueCtrl.text.trim(),
      'points': int.tryParse(pointsCtrl.text.trim()) ?? 0,
    });
    submitting.value = false;
    Get.back<bool>(result: true);
    Get.snackbar('Posted',
        '${titleCtrl.text} assigned to ${selectedClass.value}.',
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
