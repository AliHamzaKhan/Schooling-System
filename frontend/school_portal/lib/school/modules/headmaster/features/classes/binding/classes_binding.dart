import 'package:get/get.dart';

import '../controller/classes_controller.dart';

class ClassesBinding extends Bindings {
  @override
  void dependencies() {
    // Do NOT delete an existing instance: the tab-shell registers the same
    // controller and expects it to survive when the standalone `/classes`
    // route (opened from the dashboard) is popped.
    if (!Get.isRegistered<ClassesController>()) {
      Get.lazyPut<ClassesController>(() => ClassesController());
    }
  }
}
