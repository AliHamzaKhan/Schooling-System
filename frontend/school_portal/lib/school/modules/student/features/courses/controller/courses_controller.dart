import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/course_models.dart';

/// Lists the courses available to the student.
class CoursesController extends GetxController {
  final StudentRepository _repo;
  CoursesController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final courses = <Course>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadCourses();
    if (res.success && res.data != null) {
      courses.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load courses.';
    }
    loading.value = false;
  }
}
