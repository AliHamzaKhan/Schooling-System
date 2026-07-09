import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/quiz_models.dart';

/// Lists the published quizzes available to the student, each annotated with
/// their own attempt (score) if they've taken it.
class QuizzesController extends GetxController {
  final StudentRepository _repo;
  QuizzesController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final quizzes = <StudentQuiz>[].obs;

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
