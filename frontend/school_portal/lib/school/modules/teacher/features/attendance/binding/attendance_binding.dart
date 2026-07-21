import 'package:get/get.dart';

import '../controller/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherAttendanceController>(force: true);
    Get.lazyPut<TeacherAttendanceController>(() => TeacherAttendanceController());
  }
}

class AttendanceMarkBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<AttendanceMarkController>(force: true);
    Get.lazyPut<AttendanceMarkController>(() => AttendanceMarkController());
  }
}
