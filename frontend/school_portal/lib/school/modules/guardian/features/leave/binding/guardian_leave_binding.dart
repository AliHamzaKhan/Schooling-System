import 'package:get/get.dart';

import '../controller/guardian_leave_controller.dart';

class GuardianLeaveBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<GuardianLeaveController>(force: true);
    Get.lazyPut<GuardianLeaveController>(() => GuardianLeaveController());
  }
}
