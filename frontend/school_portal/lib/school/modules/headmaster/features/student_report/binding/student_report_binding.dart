import 'package:get/get.dart';

import '../controller/student_report_controller.dart';

class StudentReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<StudentReportController>(force: true);
    Get.lazyPut<StudentReportController>(() => StudentReportController());
  }
}
