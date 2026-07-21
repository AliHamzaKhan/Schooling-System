import 'package:get/get.dart';

import '../controller/exams_controller.dart';

class ExamsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<StudentExamsController>(force: true);
    Get.lazyPut<StudentExamsController>(() => StudentExamsController());
  }
}
