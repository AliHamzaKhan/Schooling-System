import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/gradebook_data.dart';

class GradebookController extends GetxController {
  final TeacherRepository _repo;
  GradebookController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final book = Rxn<Gradebook>();
  final marks = <String, int?>{}.obs;
  final controllers = <String, TextEditingController>{};
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    load(arg is String ? arg : null);
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

  Future<void> saveAll() async {
    saving.value = true;
    // TODO: POST marks to the API.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    saving.value = false;
    Get.snackbar('Marks saved',
        '$entered of ${book.value?.totalStudents ?? 0} students recorded.',
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> load(String? examId) async {
    loading.value = true;
    final res = await _repo.loadGradebook(examId);
    if (res.success && res.data != null) {
      book.value = res.data;
      for (final s in res.data!.students) {
        marks[s.id] = null;
      }
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
