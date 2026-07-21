import 'package:get/get.dart';

import '../controller/classes_controller.dart';

class ClassesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherClassesController>(force: true);
    Get.lazyPut<TeacherClassesController>(() => TeacherClassesController());
  }
}
