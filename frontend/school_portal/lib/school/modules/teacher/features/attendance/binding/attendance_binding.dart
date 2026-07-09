import 'package:get/get.dart';

import '../controller/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<AttendanceController>(force: true);
    Get.lazyPut<AttendanceController>(() => AttendanceController());
  }
}

class AttendanceMarkBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<AttendanceMarkController>(force: true);
    Get.lazyPut<AttendanceMarkController>(() => AttendanceMarkController());
  }
}
