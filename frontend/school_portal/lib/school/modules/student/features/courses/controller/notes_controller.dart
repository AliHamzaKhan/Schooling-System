import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/course_models.dart';

/// Lists the notes within a course.
class NotesController extends GetxController {
  final StudentRepository _repo;
  final Course course;
  NotesController.of(this.course, {StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final notes = <NoteBrief>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadCourseNotes(course.id);
    if (res.success && res.data != null) {
      notes.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load notes.';
    }
    loading.value = false;
  }
}
