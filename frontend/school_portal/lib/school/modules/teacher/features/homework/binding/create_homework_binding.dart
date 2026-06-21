import 'package:get/get.dart';

import '../controller/create_homework_controller.dart';

class CreateHomeworkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateHomeworkController>(() => CreateHomeworkController());
  }
}
