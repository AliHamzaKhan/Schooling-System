import 'package:get/get.dart';

import '../controller/performance_controller.dart';

class PerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<PerformanceController>(force: true);
    Get.lazyPut<PerformanceController>(() => PerformanceController());
  }
}
