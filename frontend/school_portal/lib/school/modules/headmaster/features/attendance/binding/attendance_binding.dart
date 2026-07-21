import 'package:get/get.dart';

import '../controller/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<HeadmasterAttendanceController>(force: true);
    Get.lazyPut<HeadmasterAttendanceController>(() => HeadmasterAttendanceController());
  }
}
