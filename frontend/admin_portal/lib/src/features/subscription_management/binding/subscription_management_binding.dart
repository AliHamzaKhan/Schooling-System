import 'package:get/get.dart';

import '../controller/subscription_management_controller.dart';

class SubscriptionManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SubscriptionManagementController());
  }
}
