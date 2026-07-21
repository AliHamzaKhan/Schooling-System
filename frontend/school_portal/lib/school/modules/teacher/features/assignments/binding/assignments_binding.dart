import 'package:get/get.dart';

import '../controller/assignments_controller.dart';

class AssignmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherAssignmentsController>(force: true);
    Get.lazyPut<TeacherAssignmentsController>(() => TeacherAssignmentsController());
  }
}
