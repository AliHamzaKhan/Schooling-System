import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/performance_data.dart';

/// Drives the single-student performance drill-in (from the gradebook / class
/// performance list). Requires a student id — reached only via a student tap.
class TeacherPerformanceController extends GetxController {
  final TeacherRepository _repo;
  TeacherPerformanceController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final student = Rxn<StudentDetail>();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String && arg.isNotEmpty) {
      load(arg);
    } else {
      // No student was passed — this screen is a drill-in and shouldn't be
      // reachable without one. Surface it rather than calling the API with a
      // bad id.
      error.value = 'No student selected.';
      loading.value = false;
    }
  }

  Future<void> load(String studentId) async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadStudentPerformance(studentId);
    if (res.success && res.data != null) {
      student.value = res.data;
    } else {
      error.value = res.error ?? 'Could not load this student.';
    }
    loading.value = false;
  }
}
