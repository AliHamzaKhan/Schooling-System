import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/quiz_models.dart';

/// Drives the Create Quiz form: pick a section + subject, add MCQ questions
/// (each with its own marks), then save & publish in one action.
class CreateQuizController extends GetxController {
  final TeacherRepository _repo;
  CreateQuizController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final titleCtrl = TextEditingController();

  final loadingOptions = true.obs;
  final sections = <IdLabel>[].obs;
  final subjects = <IdLabel>[].obs;
  final selectedSection = RxnString();
  final selectedSubject = RxnString();

  final questions = <DraftQuestion>[].obs;
  final submitting = false.obs;
  final generating = false.obs;
  final error = RxnString();

  // Assignment: whole class (section-wide) vs specific students.
  final assignToWholeClass = true.obs;
  final loadingRoster = false.obs;
  final roster = <IdLabel>[].obs;
  final selectedStudents = <String>{}.obs;

  /// Total marks across all questions — the quiz's total.
  double get totalMarks =>
      questions.fold<double>(0, (sum, q) => sum + q.marks);

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    loadingOptions.value = true;
    try {
      final sec = await _repo.loadSectionOptions();
      final sub = await _repo.loadSubjectOptions();
      if (sec.success) sections.assignAll(sec.data ?? const []);
      if (sub.success) subjects.assignAll(sub.data ?? const []);
    } finally {
      // Always drop the spinner so the form (and its buttons) render, even if
      // an options request throws.
      loadingOptions.value = false;
    }
  }

  void selectSection(String? v) {
    if (v == selectedSection.value) return;
    selectedSection.value = v;
    selectedStudents.clear();
    roster.clear();
    if (v != null) _loadRoster(v);
  }

  void selectSubject(String? v) => selectedSubject.value = v;

  Future<void> _loadRoster(String sectionId) async {
    loadingRoster.value = true;
    final res = await _repo.loadSectionStudents(sectionId);
    if (res.success) roster.assignAll(res.data ?? const []);
    loadingRoster.value = false;
  }

  void setAssignToWholeClass(bool value) => assignToWholeClass.value = value;

  void toggleStudent(String id) {
    selectedStudents.contains(id)
        ? selectedStudents.remove(id)
        : selectedStudents.add(id);
  }
  void addQuestion(DraftQuestion q) => questions.add(q);
  void removeQuestion(int index) {
    if (index >= 0 && index < questions.length) questions.removeAt(index);
  }

  /// Picks a PDF and has the backend AI generate draft questions from it, which
  /// are appended to the list for the teacher to review before publishing.
  Future<void> generateFromPdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      error.value = 'Could not read the selected file.';
      return;
    }
    generating.value = true;
    error.value = null;
    final res =
        await _repo.generateQuizQuestions(bytes: bytes, filename: file.name);
    generating.value = false;
    if (res.success && res.data != null) {
      questions.addAll(res.data!);
      Get.snackbar(
        'Questions generated',
        'Added ${res.data!.length} question(s) — review, then Save & Publish.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      error.value = res.error ?? 'Could not generate questions from that PDF.';
    }
  }

  /// Persists the quiz + its questions, then publishes it.
  Future<void> saveAndPublish() async {
    error.value = null;
    if (titleCtrl.text.trim().length < 2) {
      error.value = 'Give the quiz a title.';
      return;
    }
    if (selectedSection.value == null || selectedSubject.value == null) {
      error.value = 'Pick a section and a subject.';
      return;
    }
    if (questions.isEmpty) {
      error.value = 'Add at least one question.';
      return;
    }
    if (!assignToWholeClass.value && selectedStudents.isEmpty) {
      error.value = 'Pick at least one student, or assign to the whole class.';
      return;
    }
    submitting.value = true;
    final created = await _repo.createQuiz(
      sectionId: selectedSection.value!,
      subjectId: selectedSubject.value!,
      title: titleCtrl.text.trim(),
      assigneeIds:
          assignToWholeClass.value ? null : selectedStudents.toList(),
    );
    if (!created.success || (created.data ?? '').isEmpty) {
      submitting.value = false;
      error.value = created.error ?? 'Could not create the quiz.';
      return;
    }
    final quizId = created.data!;
    for (var i = 0; i < questions.length; i++) {
      final res = await _repo.addQuizQuestion(quizId, questions[i].toJson(i));
      if (!res.success) {
        submitting.value = false;
        error.value = res.error ?? 'Could not save question ${i + 1}.';
        return;
      }
    }
    final published = await _repo.publishQuiz(quizId);
    submitting.value = false;
    if (!published.success) {
      // Questions saved but publish failed — surface it; the quiz stays a draft.
      error.value = published.error ?? 'Quiz saved as draft, but publish failed.';
      return;
    }
    Get.back<bool>(result: true);
    Get.snackbar('Quiz published', 'Students can now attempt this quiz.',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    super.onClose();
  }
}
