import 'dart:async';

import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/assignment.dart';

class AssignmentsController extends GetxController {
  final TeacherRepository _repo;
  AssignmentsController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  static const classFilters = ['All Classes', 'Algebra 101', 'Calculus II'];

  final loading = true.obs;
  final error = RxnString();
  final data = Rxn<AssignmentsData>();
  final query = ''.obs;
  final classFilterIndex = 0.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void onSearch(String v) {
    query.value = v;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), fetch);
  }

  void selectClass(int i) {
    if (i == classFilterIndex.value) return;
    classFilterIndex.value = i;
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadAssignments(
        classFilter: classFilters[classFilterIndex.value]);
    if (res.success && res.data != null) {
      final q = query.value.toLowerCase();
      final base = res.data!;
      data.value = AssignmentsData(
        stats: base.stats,
        assignments: q.isEmpty
            ? base.assignments
            : base.assignments
                .where((a) => a.title.toLowerCase().contains(q))
                .toList(),
      );
    } else {
      error.value = res.error ?? 'Could not load assignments.';
    }
    loading.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
