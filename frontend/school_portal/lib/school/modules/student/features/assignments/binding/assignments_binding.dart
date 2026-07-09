import 'package:get/get.dart';

import '../controller/assignments_controller.dart';

class AssignmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<AssignmentsController>(force: true);
    Get.lazyPut<AssignmentsController>(() => AssignmentsController());
  }
}
