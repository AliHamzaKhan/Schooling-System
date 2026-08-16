import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../../quiz/models/quiz_models.dart' show IdLabel;

/// One subject paper being drafted for an exam: a subject plus its marks.
///
/// Plain data only — the paper card on screen owns the `TextEditingController`s
/// that edit these values, so they are disposed when that card leaves the tree.
class PaperRow {
  String? subjectId;
  String maxMarks = '100';
  String passMarks = '40';
}

/// Drives Create Exam, shaped to what the backend actually stores: an exam
/// (name + class + date range) with one or more subject papers (subject +
/// max/pass marks). Question-authoring lives in the separate Quiz feature.
class CreateExamController extends GetxController {
  final TeacherRepository _repo;
  CreateExamController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  /// Field values. Their `TextEditingController`s belong to [CreateExamView]'s
  /// State and are disposed with that screen.
  final name = ''.obs;

  final loadingOptions = true.obs;
  final classes = <IdLabel>[].obs;
  final subjects = <IdLabel>[].obs;
  final selectedClass = RxnString();

  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final startText = ''.obs;
  final endText = ''.obs;

  /// Subject papers — at least one is required.
  final papers = <PaperRow>[PaperRow()].obs;

  final submitting = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    loadingOptions.value = true;
    // Class options carry the real class UUID (id); the label is human-facing.
    final cls = await _repo.loadClasses();
    final sub = await _repo.loadSubjectOptions();
    if (cls.success) {
      classes.assignAll([
        for (final c in cls.data ?? const [])
          IdLabel(
            c.id,
            [c.grade, c.subject].where((s) => s.isNotEmpty).join(' · '),
          ),
      ]);
    }
    if (sub.success) subjects.assignAll(sub.data ?? const []);
    loadingOptions.value = false;
  }

  void selectClass(String? v) => selectedClass.value = v;
  void selectPaperSubject(int i, String? v) {
    if (i >= 0 && i < papers.length) {
      papers[i].subjectId = v;
      papers.refresh();
    }
  }

  void addPaper() => papers.add(PaperRow());
  void removePaper(int i) {
    if (papers.length <= 1) return;
    papers.removeAt(i);
  }

  Future<void> pickStartDate(BuildContext context) async {
    final d = await _pick(context, startDate.value);
    if (d == null) return;
    startDate.value = d;
    startText.value = _display(d);
  }

  Future<void> pickEndDate(BuildContext context) async {
    final d = await _pick(context, endDate.value ?? startDate.value);
    if (d == null) return;
    endDate.value = d;
    endText.value = _display(d);
  }

  Future<DateTime?> _pick(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
  }

  String _display(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> save() async {
    error.value = null;
    if (name.value.trim().length < 2) {
      error.value = 'Give the exam a name.';
      return;
    }
    if (selectedClass.value == null) {
      error.value = 'Pick the class sitting this exam.';
      return;
    }

    // Validate every paper: a subject and sane marks.
    final drafts = <ExamPaperDraft>[];
    for (final p in papers) {
      if (p.subjectId == null) {
        error.value = 'Choose a subject for every paper.';
        return;
      }
      final max = double.tryParse(p.maxMarks.trim());
      final pass = double.tryParse(p.passMarks.trim());
      if (max == null || max <= 0) {
        error.value = 'Enter valid maximum marks for every paper.';
        return;
      }
      if (pass == null || pass < 0 || pass > max) {
        error.value = 'Pass marks must be between 0 and the maximum.';
        return;
      }
      drafts.add(ExamPaperDraft(
          subjectId: p.subjectId!, maxMarks: max, passMarks: pass));
    }
    if (startDate.value != null &&
        endDate.value != null &&
        endDate.value!.isBefore(startDate.value!)) {
      error.value = 'The end date is before the start date.';
      return;
    }

    submitting.value = true;
    final res = await _repo.createExam(
      classId: selectedClass.value!,
      name: name.value.trim(),
      startDate: startDate.value == null ? null : _iso(startDate.value!),
      endDate: endDate.value == null ? null : _iso(endDate.value!),
      papers: drafts,
    );
    submitting.value = false;

    if (!res.success) {
      error.value = res.error ?? 'Could not create the exam.';
      return;
    }
    Get.back<bool>(result: true);
    Get.snackbar('Exam created', '“${name.value.trim()}” is scheduled.',
        snackPosition: SnackPosition.BOTTOM);
  }
}
