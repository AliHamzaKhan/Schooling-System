import 'package:get/get.dart';

import '../controller/teachers_controller.dart';

class TeachersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeachersController>(() => TeachersController());
  }
}
