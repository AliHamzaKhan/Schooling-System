import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';

/// Registers the Student Dashboard controller, which aggregates the student's
/// live assignments / exams / attendance.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<DashboardController>(force: true);
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
