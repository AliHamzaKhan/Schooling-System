import 'package:get/get.dart';

import '../controller/attendance_controller.dart';

class GuardianAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GuardianAttendanceController>(
        () => GuardianAttendanceController());
  }
}
