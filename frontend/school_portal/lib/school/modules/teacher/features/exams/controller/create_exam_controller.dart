import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';

/// Drives the Create Exam form (Basic Info, Content, Logistics, Grading).
class CreateExamController extends GetxController {
  final TeacherRepository _repo;
  CreateExamController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  static const subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'];
  static const classes = ['Algebra 101', 'Calculus II', 'Physics 11', 'Chemistry 11'];

  final titleCtrl = TextEditingController();
  final instructionsCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final totalMarksCtrl = TextEditingController(text: '100');

  final selectedSubject = RxnString();
  final selectedClass = RxnString();
  final autoGrading = true.obs;
  final questionsAdded = 0.obs;
  final submitting = false.obs;
  final savingDraft = false.obs;
  final error = RxnString();

  void selectSubject(String? v) => selectedSubject.value = v;
  void selectClass(String? v) => selectedClass.value = v;
  void toggleAutoGrading(bool v) => autoGrading.value = v;

  Future<void> save({required bool asDraft}) async {
    error.value = null;
    if (!asDraft && titleCtrl.text.trim().isEmpty) {
      error.value = 'Give the exam a title before saving.';
      return;
    }
    if (asDraft) {
      savingDraft.value = true;
    } else {
      submitting.value = true;
    }
    await _repo.createExam({
      'title': titleCtrl.text.trim(),
      'instructions': instructionsCtrl.text.trim(),
      'subject': selectedSubject.value,
      'class': selectedClass.value,
      'date': dateCtrl.text.trim(),
      'start': startCtrl.text.trim(),
      'end': endCtrl.text.trim(),
      'duration': durationCtrl.text.trim(),
      'total_marks': int.tryParse(totalMarksCtrl.text.trim()) ?? 0,
      'auto_grading': autoGrading.value,
      'is_draft': asDraft,
    });
    submitting.value = false;
    savingDraft.value = false;
    Get.back<bool>(result: true);
    Get.snackbar(
      asDraft ? 'Draft saved' : 'Exam created',
      asDraft ? 'You can publish it later.' : 'Students will see it shortly.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    instructionsCtrl.dispose();
    dateCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
    durationCtrl.dispose();
    totalMarksCtrl.dispose();
    super.onClose();
  }
}
