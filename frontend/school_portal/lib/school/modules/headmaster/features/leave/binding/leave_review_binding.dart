import 'package:get/get.dart';

import '../controller/leave_review_controller.dart';

class LeaveReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<LeaveReviewController>(force: true);
    Get.lazyPut<LeaveReviewController>(() => LeaveReviewController());
  }
}
