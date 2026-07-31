import 'package:get/get.dart';

import '../controller/exam_categories_controller.dart';

class ExamCategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamCategoriesController>(() => ExamCategoriesController());
  }
}
