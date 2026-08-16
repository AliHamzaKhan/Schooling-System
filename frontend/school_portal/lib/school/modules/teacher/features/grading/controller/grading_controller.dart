import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../../../widgets/action_form_sheet.dart';
import '../../../data/teacher_repository.dart';
import '../../assignments/models/assignment.dart';
import '../models/submission_row.dart';

/// Drives the grading screen for a single assignment: lists its submissions and
/// records marks + feedback for each. Opening the list also marks every
/// submission "seen" on the backend (the student's read receipt).
class GradingController extends GetxController {
  final TeacherRepository _repo;
  final Assignment assignment;
  GradingController.of(this.assignment, {TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final submissions = <SubmissionRow>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadSubmissions(assignment.id);
    if (res.success && res.data != null) {
      submissions.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load submissions.';
    }
    loading.value = false;
  }

  int get gradedCount => submissions.where((s) => s.isGraded).length;

  Future<void> gradeFlow(SubmissionRow row) async {
    final marks = TextEditingController(
        text: row.marksObtained == null
            ? ''
            : (row.marksObtained! == row.marksObtained!.roundToDouble()
                ? row.marksObtained!.toInt().toString()
                : row.marksObtained!.toString()));
    final feedback = TextEditingController(text: row.feedback ?? '');
    final max = assignment.maxMarks;
    final ok = await showActionFormSheet(
      title: 'Grade — ${row.studentName ?? 'Student'}',
      // The sheet owns these fields and disposes them when it closes.
      ownedControllers: [marks, feedback],
      fields: [
        GlassInput(
          label: max == null ? 'Marks' : 'Marks (out of ${_fmt(max)})',
          hint: 'e.g. 8',
          controller: marks,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        GlassInput(
          label: 'Feedback (optional)',
          hint: 'A note for the student…',
          controller: feedback,
          keyboardType: TextInputType.multiline,
        ),
      ],
      onSubmit: () async {
        final value = double.tryParse(marks.text.trim());
        if (value == null || value < 0) return 'Enter a valid mark';
        if (max != null && value > max) {
          return 'Marks cannot exceed ${_fmt(max)}';
        }
        final res = await _repo.gradeSubmission(
          submissionId: row.id,
          marks: value,
          feedback: feedback.text.trim().isEmpty ? null : feedback.text.trim(),
        );
        return res.success ? null : (res.error ?? 'Could not save the grade');
      },
    );
    if (ok == true) {
      await load();
      Get.snackbar('Graded', 'Marks saved.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
