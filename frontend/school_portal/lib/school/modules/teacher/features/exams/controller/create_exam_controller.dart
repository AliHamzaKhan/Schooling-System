import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/exam_question.dart';

/// Drives the Create Exam form (Basic Info, Content, Logistics, Grading).
///
/// Subject options come from the school's subject catalog
/// (`/academic/subjects`); class options come from the teacher's own
/// (school-scoped) classes — not a hardcoded list.
class CreateExamController extends GetxController {
  final TeacherRepository _repo;
  CreateExamController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final titleCtrl = TextEditingController();
  final instructionsCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final totalMarksCtrl = TextEditingController(text: '100');

  // Options derived from the teacher's live classes.
  final loadingOptions = true.obs;
  final subjects = <String>[].obs;
  final classes = <String>[].obs;

  final selectedSubject = RxnString();
  final selectedClass = RxnString();
  final autoGrading = true.obs;

  // Exam content built in-app.
  final questions = <ExamQuestion>[].obs;
  final pdfName = RxnString();

  // Logistics — backed by real pickers.
  final examDate = Rxn<DateTime>();
  final startTime = Rxn<TimeOfDay>();
  final endTime = Rxn<TimeOfDay>();

  final submitting = false.obs;
  final savingDraft = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
  }

  /// Loads distinct Subject options from the school's subject catalog and
  /// "Grade · Class" labels from the teacher's classes for the two dropdowns.
  Future<void> _loadOptions() async {
    loadingOptions.value = true;

    // Subjects come from the subject catalog — NOT from class names.
    final subjectsRes = await _repo.loadSubjects();
    final seenSubjects = <String>{};
    final subs = <String>[];
    for (final name in subjectsRes.data ?? const <String>[]) {
      if (name.isNotEmpty && seenSubjects.add(name)) subs.add(name);
    }

    // Class options are derived from the teacher's own classes.
    final res = await _repo.loadClasses();
    final seenClasses = <String>{};
    final cls = <String>[];
    for (final c in res.data ?? const []) {
      final label =
          [c.grade, c.subject].where((s) => s.isNotEmpty).join(' · ');
      final value = label.isEmpty ? c.id : label;
      if (seenClasses.add(value)) cls.add(value);
    }

    subjects.assignAll(subs);
    classes.assignAll(cls);
    loadingOptions.value = false;
  }

  void selectSubject(String? v) => selectedSubject.value = v;
  void selectClass(String? v) => selectedClass.value = v;
  void toggleAutoGrading(bool v) => autoGrading.value = v;

  void addQuestion(ExamQuestion q) => questions.add(q);
  void removeQuestion(int index) {
    if (index >= 0 && index < questions.length) questions.removeAt(index);
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: examDate.value ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    examDate.value = picked;
    dateCtrl.text = _formatDate(picked);
  }

  Future<void> pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime.value ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    startTime.value = picked;
    if (!context.mounted) return;
    startCtrl.text = picked.format(context);
  }

  Future<void> pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime.value ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    endTime.value = picked;
    if (!context.mounted) return;
    endCtrl.text = picked.format(context);
  }

  /// Opens the OS file picker filtered to PDFs and records the chosen name.
  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      pdfName.value = result.files.first.name;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/${d.year}';

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
      'questions': questions.map((q) => q.toJson()).toList(),
      'attachment': pdfName.value,
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
