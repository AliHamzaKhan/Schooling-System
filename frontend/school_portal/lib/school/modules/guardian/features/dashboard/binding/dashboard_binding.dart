import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';

class GuardianDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<GuardianDashboardController>(force: true);
    Get.lazyPut<GuardianDashboardController>(
        () => GuardianDashboardController());
  }
}
