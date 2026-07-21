import 'package:get/get.dart';

import '../controller/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<StudentAttendanceController>(force: true);
    Get.lazyPut<StudentAttendanceController>(() => StudentAttendanceController());
  }
}
