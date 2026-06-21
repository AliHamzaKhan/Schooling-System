import 'package:get/get.dart';

import '../controller/homework_controller.dart';

class HomeworkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeworkController>(() => HomeworkController());
  }
}
