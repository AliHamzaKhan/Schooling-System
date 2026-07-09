import 'package:get/get.dart';

import '../../../data/student_repository.dart';
import '../../quiz/models/quiz_models.dart';
import '../models/exam_result.dart';

/// Aggregates the student's academic results — published exam grades and
/// attempted quiz scores.
class ResultsController extends GetxController {
  final StudentRepository _repo;
  ResultsController({StudentRepository? repo})
      : _repo = repo ?? Get.find<StudentRepository>();

  final loading = true.obs;
  final error = RxnString();
  final exams = <ExamResultItem>[].obs;
  final quizzes = <StudentQuiz>[].obs; // attempted only

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final examRes = await _repo.loadExamResults();
    final quizRes = await _repo.loadQuizzes();
    if (examRes.success) exams.assignAll(examRes.data ?? const []);
    // Only quizzes the student has actually attempted count as results.
    if (quizRes.success) {
      quizzes.assignAll(
        (quizRes.data ?? const <StudentQuiz>[])
            .where((q) => q.attempt != null)
            .toList(),
      );
    }
    if (!examRes.success && !quizRes.success) {
      error.value = examRes.error ?? 'Could not load your results.';
    }
    loading.value = false;
  }

  /// Average across published exam results (0 when none).
  int get examAverage {
    if (exams.isEmpty) return 0;
    final sum = exams.fold<double>(0, (a, e) => a + e.percentage);
    return (sum / exams.length).round();
  }
}
