import 'package:get/get.dart';

import '../controller/leave_review_controller.dart';

class TeacherLeaveReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<TeacherLeaveReviewController>(force: true);
    Get.lazyPut<TeacherLeaveReviewController>(
        () => TeacherLeaveReviewController());
  }
}
