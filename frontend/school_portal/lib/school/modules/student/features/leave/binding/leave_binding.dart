import 'package:get/get.dart';

import '../controller/leave_controller.dart';

class LeaveBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<LeaveController>(force: true);
    Get.lazyPut<LeaveController>(() => LeaveController());
  }
}
