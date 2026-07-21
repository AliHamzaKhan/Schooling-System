import 'package:get/get.dart';

import '../controller/timetable_controller.dart';

class TimetableBinding extends Bindings {
  @override
  void dependencies() {
    // Replace any stale same-named controller from another role's module.
    Get.delete<StudentTimetableController>(force: true);
    Get.lazyPut<StudentTimetableController>(() => StudentTimetableController());
  }
}
