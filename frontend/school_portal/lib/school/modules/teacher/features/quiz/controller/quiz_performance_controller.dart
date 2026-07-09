import 'package:get/get.dart';

import '../../../data/teacher_repository.dart';
import '../models/quiz_models.dart';

/// Loads per-student scores for one quiz.
class QuizPerformanceController extends GetxController {
  final TeacherRepository _repo;
  QuizPerformanceController({TeacherRepository? repo})
      : _repo = repo ?? Get.find<TeacherRepository>();

  final loading = true.obs;
  final error = RxnString();
  final performance = Rxn<QuizPerformance>();
  final title = 'Quiz'.obs;

  String _quizId = '';

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is TeacherQuiz) {
      _quizId = arg.id;
      title.value = arg.title;
    } else if (arg is String) {
      _quizId = arg;
    }
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadQuizPerformance(_quizId);
    if (res.success && res.data != null) {
      performance.value = res.data;
      if (res.data!.title.isNotEmpty) title.value = res.data!.title;
    } else {
      error.value = res.error ?? 'Could not load performance.';
    }
    loading.value = false;
  }
}
