import 'package:get/get.dart';

import '../controller/subscription_settings_controller.dart';

class SubscriptionSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionSettingsController>(
        () => SubscriptionSettingsController());
  }
}
