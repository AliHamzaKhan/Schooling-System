import 'package:get/get.dart';

import '../controller/exam_timetable_controller.dart';

class ExamTimetableBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamTimetableController>(() => ExamTimetableController());
  }
}
