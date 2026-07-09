import 'package:get/get.dart';

import '../controller/classes_controller.dart';

class ClassesBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<ClassesController>(force: true);
    Get.lazyPut<ClassesController>(() => ClassesController());
  }
}
