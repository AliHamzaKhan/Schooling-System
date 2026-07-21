import 'package:get/get.dart';

import '../controller/class_performance_controller.dart';
import '../controller/performance_controller.dart';

class PerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<ClassPerformanceController>(force: true);
    Get.lazyPut<ClassPerformanceController>(() => ClassPerformanceController());
    Get.delete<TeacherPerformanceController>(force: true);
    Get.lazyPut<TeacherPerformanceController>(() => TeacherPerformanceController());
  }
}
