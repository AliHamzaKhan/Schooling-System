import 'package:get/get.dart';

import '../controller/create_quiz_controller.dart';
import '../controller/quiz_performance_controller.dart';
import '../controller/quizzes_controller.dart';

class QuizzesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherQuizzesController>(force: true);
    Get.lazyPut<TeacherQuizzesController>(() => TeacherQuizzesController());
  }
}

class CreateQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<CreateQuizController>(force: true);
    Get.lazyPut<CreateQuizController>(() => CreateQuizController());
  }
}

class QuizPerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<QuizPerformanceController>(force: true);
    Get.lazyPut<QuizPerformanceController>(() => QuizPerformanceController());
  }
}
