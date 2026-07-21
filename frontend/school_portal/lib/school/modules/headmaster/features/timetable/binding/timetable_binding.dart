import 'package:get/get.dart';

import '../controller/timetable_controller.dart';

class TimetableBinding extends Bindings {
  @override
  void dependencies() {
    // Replace any stale same-named controller from another role's module
    // (GetX keys instances by class name).
    Get.delete<HeadmasterTimetableController>(force: true);
    Get.lazyPut<HeadmasterTimetableController>(() => HeadmasterTimetableController());
  }
}
