import 'package:get/get.dart';

import '../../assignments/models/assignment.dart';
import '../controller/grading_controller.dart';

class GradingBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<GradingController>(force: true);
    Get.lazyPut<GradingController>(
        () => GradingController.of(Get.arguments as Assignment));
  }
}
