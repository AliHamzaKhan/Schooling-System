import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../models/quiz_models.dart';

/// Drives a single quiz attempt: load the questions, collect one answer per
/// question, submit for auto-grading, and hold the returned result.
class TakeQuizController extends GetxController {
  final StudentRepository _repo;
  TakeQuizController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final quiz = Rxn<StudentQuizDetail>();
  final submitting = false.obs;
  final result = Rxn<QuizResult>();

  /// question id → chosen option.
  final answers = <String, String>{}.obs;

  String _quizId = '';
  String title = 'Quiz';

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is StudentQuiz) {
      _quizId = arg.id;
      title = arg.title;
    } else if (arg is String) {
      _quizId = arg;
    }
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final res = await _repo.loadQuizDetail(_quizId);
    if (res.success && res.data != null) {
      quiz.value = res.data;
      if (res.data!.title.isNotEmpty) title = res.data!.title;
    } else {
      error.value = res.error ?? 'Could not load this quiz.';
    }
    loading.value = false;
  }

  void select(String questionId, String option) =>
      answers[questionId] = option;

  int get answeredCount => answers.length;

  bool get allAnswered {
    final q = quiz.value;
    return q != null &&
        q.questions.isNotEmpty &&
        q.questions.every((question) => answers.containsKey(question.id));
  }

  Future<void> submit() async {
    if (!allAnswered) {
      error.value = 'Answer every question before submitting.';
      return;
    }
    submitting.value = true;
    error.value = null;
    final res = await _repo.submitQuiz(_quizId, answers);
    submitting.value = false;
    if (res.success && res.data != null) {
      result.value = res.data;
    } else {
      error.value = res.error ?? 'Could not submit. Please try again.';
    }
  }
}
