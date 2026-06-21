import 'package:get/get.dart';

import '../controller/subscriptions_controller.dart';

class SubscriptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionsController>(() => SubscriptionsController());
  }
}
