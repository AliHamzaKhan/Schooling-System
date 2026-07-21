import 'package:get/get.dart';

import '../controller/quizzes_controller.dart';
import '../controller/take_quiz_controller.dart';

class QuizzesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<StudentQuizzesController>(force: true);
    Get.lazyPut<StudentQuizzesController>(() => StudentQuizzesController());
  }
}

class TakeQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TakeQuizController>(force: true);
    Get.lazyPut<TakeQuizController>(() => TakeQuizController());
  }
}
