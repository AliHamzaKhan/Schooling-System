import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherDashboardController>(force: true);
    Get.lazyPut<TeacherDashboardController>(() => TeacherDashboardController());
  }
}
