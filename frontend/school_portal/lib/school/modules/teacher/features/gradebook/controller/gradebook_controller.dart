import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/gradebook_data.dart';

class GradebookController extends GetxController {
  final TeacherRepository _repo;
  GradebookController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final book = Rxn<Gradebook>();

  /// Papers the teacher can grade, shown when none was passed in.
  final papers = <GradablePaper>[].obs;
  final selectedPaperId = RxnString();

  final marks = <String, int?>{}.obs;
  final controllers = <String, TextEditingController>{};
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String && arg.isNotEmpty) {
      selectedPaperId.value = arg;
      load(arg);
    } else {
      // No paper chosen yet — offer the real list rather than inventing one.
      loadPapers();
    }
  }

  int get entered => marks.values.where((v) => v != null).length;
  int get classAveragePercent {
    final scored = marks.values.whereType<int>().toList();
    if (scored.isEmpty || book.value == null) return 0;
    final total = book.value!.totalMarks * scored.length;
    final sum = scored.fold<int>(0, (a, b) => a + b);
    return ((sum / total) * 100).round();
  }

  TextEditingController controllerFor(String id) =>
      controllers.putIfAbsent(id, () => TextEditingController());

  void setMark(String studentId, String raw) {
    final parsed = int.tryParse(raw.trim());
    final max = book.value?.totalMarks ?? 100;
    if (parsed == null) {
      marks[studentId] = null;
      return;
    }
    marks[studentId] = parsed.clamp(0, max);
  }

  Future<void> loadPapers() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadGradablePapers();
    if (res.success) {
      papers.assignAll(res.data ?? const []);
    } else {
      error.value = res.error ?? 'Could not load exam papers.';
    }
    loading.value = false;
  }

  Future<void> selectPaper(String paperId) async {
    selectedPaperId.value = paperId;
    await load(paperId);
  }

  Future<void> saveAll() async {
    final paperId = selectedPaperId.value;
    if (paperId == null) return;

    // Only send marks that were actually entered — a blank field means "not
    // graded yet", not zero.
    final entries = <String, double>{
      for (final e in marks.entries)
        if (e.value != null) e.key: e.value!.toDouble(),
    };
    if (entries.isEmpty) {
      Get.snackbar('Nothing to save', 'Enter at least one mark first.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    saving.value = true;
    final res = await _repo.saveMarks(paperId, entries);
    saving.value = false;

    if (!res.success) {
      Get.snackbar('Could not save', res.error ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.snackbar('Marks saved',
        '${entries.length} of ${book.value?.totalStudents ?? 0} students recorded.',
        snackPosition: SnackPosition.BOTTOM);
    // Re-read so the sheet reflects what the server actually stored.
    await load(paperId);
  }

  Future<void> load(String paperId) async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadGradebook(paperId);
    if (res.success && res.data != null) {
      book.value = res.data;
      // Seed the fields with marks already stored, so editing an existing
      // sheet shows what's there rather than blanking it.
      marks.clear();
      for (final s in res.data!.students) {
        marks[s.id] = s.marks?.round();
        controllerFor(s.id).text = s.marks == null ? '' : '${s.marks!.round()}';
      }
    } else {
      error.value = res.error ?? 'Could not load this marks sheet.';
    }
    loading.value = false;
  }

  @override
  void onClose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.onClose();
  }
}
