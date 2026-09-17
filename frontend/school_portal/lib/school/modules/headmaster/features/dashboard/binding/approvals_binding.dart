import 'package:get/get.dart';

import '../controller/approvals_controller.dart';

class ApprovalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.delete<ApprovalsController>(force: true);
    Get.lazyPut<ApprovalsController>(() => ApprovalsController());
  }
}
