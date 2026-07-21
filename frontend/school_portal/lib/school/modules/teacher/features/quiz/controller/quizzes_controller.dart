import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/quiz_models.dart';

/// Lists the teacher's quizzes (draft + published).
class TeacherQuizzesController extends GetxController {
  final TeacherRepository _repo;
  TeacherQuizzesController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final quizzes = <TeacherQuiz>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadQuizzes();
    if (res.success && res.data != null) {
      quizzes.assignAll(res.data!);
    } else {
      error.value = res.error ?? 'Could not load quizzes.';
    }
    loading.value = false;
  }
}
